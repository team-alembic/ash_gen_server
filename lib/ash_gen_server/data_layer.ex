defmodule AshGenServer.DataLayer do
  @moduledoc """
  An Ash Datalayer backed by individual GenServers.

  You probably don't actually want this, except in very specific circumstances.
  If you merely want in-memory storage of resources then take a look at
  `Ash.DataLayer.Ets`.

  ## Caveats:
  * When a resource using this datalayer is created it spawns an instance of
    `AshGenServer.Server` and performs all operations on the data within it.
    This means that your actions must pay the price of a `GenServer.call/3` to
    read or modify the data.
  * When destroying a resource it's process is terminated and it's internal
    state is lost.
  * If, for some reason, the `AshGenServer.Server` process crashes or exits for
    an abnormal reason the supervisor will restart it **with the changeset used
    by the `create` action** - this means that any updates performed since
    creation will be lost.
  * Any resource using this data source **must** have at least one primary key
    field.
  * Retrieving a resource by primary key is an optimised case, but any other
    queries will pay the price of having to query every `AshGenServer.Server`
    process in sequence.
  """

  @gen_server %Ash.Dsl.Section{
    name: :gen_server,
    describe: """
    Configuration for the underlying GenServer process.
    """,
    examples: [
      """
      gen_server do
        inactivity_timeout :timer.minutes(5)
        maximum_lifetime :timer.minutes(120)
      end
      """
    ],
    schema: [
      inactivity_timeout: [
        type: :timeout,
        default: :infinity,
        doc:
          "How long to wait before destroying the resource when it is inactive (in milliseconds). Defaults to `:infinity`."
      ],
      maximum_lifetime: [
        type: :timeout,
        default: :infinity,
        doc:
          "The maximum amount of time that the process can run (in milliseconds). Defaults to `:infinity`."
      ]
    ]
  }

  use Ash.Dsl.Extension, transformers: [], sections: [@gen_server]
  alias Ash.{Actions, Api, Changeset, DataLayer, Filter, Resource, Sort}
  alias AshGenServer.{Query, Registry, Server, Supervisor}
  @behaviour Ash.DataLayer

  @doc false
  @impl true
  @spec can?(Resource.t(), DataLayer.feature()) :: boolean
  def can?(_, :composite_primary_key), do: true
  def can?(_, :create), do: true
  def can?(_, :read), do: true
  def can?(_, :update), do: true
  def can?(_, :destroy), do: true
  def can?(_, :filter), do: true
  def can?(_, :limit), do: true
  def can?(_, :boolean_filter), do: true
  def can?(_, :nested_expressions), do: true
  def can?(_, {:filter_expr, _}), do: true
  def can?(_, _), do: false

  @doc false
  @impl true
  @spec resource_to_query(Resource.t(), Api.t()) :: Query.t()
  def resource_to_query(resource, api), do: %Query{resource: resource, api: api}

  @doc false
  @impl true
  @spec filter(Query.t(), Filter.t(), Resource.t()) :: Query.t()
  def filter(%{resource: resource, filter: nil} = query, filter, resource),
    do: {:ok, %{query | filter: filter}}

  def filter(%{resource: resource} = query, filter, resource) do
    with {:ok, filter} <- Filter.add_to_filter(query.filter, filter),
         do: {:ok, %{query | filter: filter}}
  end

  @doc false
  @impl true
  @spec limit(Query.t(), limit, Resource.t()) :: Query.t() when limit: non_neg_integer()
  def limit(%{resource: resource} = query, limit, resource), do: {:ok, %{query | limit: limit}}

  @doc false
  @impl true
  @spec offset(Query.t(), offset, Resource.t()) :: Query.t() when offset: non_neg_integer()
  def offset(%{resource: resource} = query, offset, resource),
    do: {:ok, %{query | offset: offset}}

  @doc false
  @impl true
  @spec sort(Query.t(), Sort.t(), Resource.t()) :: Query.t()
  def sort(%{resource: resource} = query, sort, resource), do: {:ok, %{query | sort: sort}}

  @doc false
  @impl true
  @spec run_query(Query.t(), Resource.t()) :: {:ok, Enum.t(Resource.t())} | {:error, any}
  def run_query(%Query{resource: resource, filter: nil} = query, resource),
    do: do_slow_query(query, resource)

  # attempt to detect and accellerate the case of `get(primary_key)`
  def run_query(
        %Query{resource: resource, filter: filter} = query,
        resource
      ) do
    primary_key_fields =
      resource
      |> Resource.Info.primary_key()
      |> MapSet.new()

    primary_key_preds =
      primary_key_fields
      |> Stream.map(&{&1, Filter.find_simple_equality_predicate(filter, &1)})
      |> Stream.filter(&elem(&1, 1))
      |> Enum.into(%{})

    primary_search_keys = primary_key_preds |> Map.keys() |> MapSet.new()

    if MapSet.equal?(primary_search_keys, primary_key_fields) do
      with {:ok, pid} <-
             Registry.find_server_by_resource_key({resource, primary_key_preds}),
           {:ok, data} <- Server.get(pid) do
        {:ok, [data]}
      else
        {:error, :not_found} -> {:ok, []}
        {:error, reason} -> {:error, reason}
      end
    else
      do_slow_query(query, resource)
    end
  end

  defp do_slow_query(query, resource) do
    result =
      resource
      |> Registry.find_servers_by_resource()
      |> Stream.map(&elem(&1, 1))
      |> Stream.map(&Server.get/1)
      |> Stream.filter(&is_tuple/1)
      |> Stream.filter(&(elem(&1, 0) == :ok))
      |> Stream.map(&elem(&1, 1))
      |> maybe_apply(query.filter, fn stream ->
        Stream.filter(stream, &Filter.Runtime.matches?(query.api, &1, query.filter))
      end)
      |> maybe_apply(query.sort, &Actions.Sort.runtime_sort(Enum.to_list(&1), query.sort))
      |> maybe_apply(query.offset, &Stream.drop(&1, query.offset))
      |> maybe_apply(query.limit, &Stream.take(&1, query.limit))
      |> Enum.to_list()

    {:ok, result}
  end

  defp maybe_apply(stream, nil, _), do: stream
  defp maybe_apply(stream, _, callback), do: callback.(stream)

  @doc false
  @impl true
  @spec create(Resource.t(), Changeset.t()) :: {:ok, Resource.t()} | {:error, any}
  def create(resource, changeset) do
    with {:ok, pid} <- Supervisor.start_server(resource, changeset),
         do: Server.get(pid)
  end

  @doc false
  @impl true
  @spec update(Resource.t(), Changeset.t()) :: {:ok, Resource.t()} | {:error, any}
  def update(resource, changeset) do
    resource_key = resource_key_from_resource_and_changeset(resource, changeset)

    with {:ok, pid} <- Registry.find_server_by_resource_key(resource_key),
         do: Server.update(pid, resource, changeset)
  end

  @doc false
  @impl true
  @spec destroy(Resource.t(), Changeset.t()) :: :ok | {:error, any}
  def destroy(resource, changeset) do
    resource_key = resource_key_from_resource_and_changeset(resource, changeset)

    Supervisor.stop_server(resource_key)
  end

  defp resource_key_from_resource_and_changeset(resource, changeset) do
    {resource, primary_key_from_resource_and_changeset(resource, changeset)}
  end

  defp primary_key_from_resource_and_changeset(resource, changeset) do
    resource
    |> Resource.Info.primary_key()
    |> Enum.into(%{}, &{&1, Changeset.get_attribute(changeset, &1)})
  end
end
