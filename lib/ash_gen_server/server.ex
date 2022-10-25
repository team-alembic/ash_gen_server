defmodule AshGenServer.Server do
  @moduledoc """
  The main resource server.

  This module is a `GenServer` which can create, read and update a single
  resource stored within it's state by applying changesets.
  """
  defstruct ~w[primary_key resource record inactivity_timeout maximum_lifetime inactivity_timer lifetime_timer api]a
  alias Ash.{Changeset, Resource}
  alias AshGenServer.Registry
  alias Spark.Dsl.Extension
  use GenServer, restart: :transient

  @type t :: %__MODULE__{
          api: module,
          primary_key: Registry.primary_key(),
          resource: Resource.t(),
          record: Resource.record(),
          inactivity_timeout: pos_integer() | :infinity,
          maximum_lifetime: pos_integer() | :infinity,
          inactivity_timer: nil | reference,
          lifetime_timer: nil | reference
        }

  @doc false
  @spec start_link(list) :: GenServer.on_start()
  def start_link(args), do: GenServer.start_link(__MODULE__, args)

  @doc """
  Retrieve the current state of the stored record.
  """
  @spec get(GenServer.server()) :: {:ok, Resource.record()} | no_return
  def get(server), do: GenServer.call(server, :get)

  @doc """
  Update the stored record by applying the provided changeset.
  """
  @spec update(GenServer.server(), Resource.t(), Changeset.t()) ::
          {:ok, Resource.record()} | {:error, any}
  def update(server, resource, changeset),
    do: GenServer.call(server, {:update, resource, changeset})

  @doc false
  @impl true
  @spec init(list) :: {:ok, t} | {:stop, {:error, any}}
  def init([resource, changeset]) do
    primary_key = primary_key_from_resource_and_changeset(resource, changeset)

    with {:ok, _self} <- Registry.register({resource, primary_key}),
         {:ok, record} <- Changeset.apply_attributes(changeset) do
      record = unload_relationships(resource, record)
      inactivity_timeout = get_config(resource, :inactivity_timeout, :infinity)
      maximum_lifetime = get_config(resource, :maximum_lifetime, :infinity)

      state =
        %__MODULE__{
          api: changeset.api,
          primary_key: primary_key,
          resource: resource,
          record: record,
          inactivity_timeout: inactivity_timeout,
          maximum_lifetime: maximum_lifetime
        }
        |> maybe_set_inactivity_timer()
        |> maybe_set_lifetime_timer()

      {:ok, state}
    else
      {:error, {:already_registered, _}} -> {:stop, :already_exists}
      {:error, reason} -> {:stop, {:error, reason}}
    end
  end

  @doc false
  @impl true
  @spec handle_call(:get | {:update, Resource.t(), Changeset.t()}, GenServer.from(), t) ::
          {:reply, {:ok, Resource.record()} | {:error, any}, t}
  def handle_call(:get, _from, state) do
    state = maybe_set_inactivity_timer(state)

    {:reply, {:ok, state.record}, state}
  end

  def handle_call({:update, resource, changeset}, _from, state) when state.resource == resource do
    state = maybe_set_inactivity_timer(state)

    case Changeset.apply_attributes(changeset) do
      {:ok, new_record} ->
        primary_key_fields = state.resource |> Resource.Info.primary_key()
        maybe_new_primary_key = Map.take(new_record, primary_key_fields)

        state =
          if maybe_new_primary_key != state.primary_key do
            Registry.unregister({state.resource, state.primary_key})
            Registry.register({state.resource, maybe_new_primary_key})
            %{state | record: new_record, primary_key: maybe_new_primary_key}
          else
            %{state | record: new_record}
          end

        {:reply, {:ok, new_record}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:update, resource, _changeset}, _from, state),
    do: {:reply, {:error, {:incorrect_resource, resource}}, state}

  @doc false
  @impl true
  @spec handle_info(:inactivity_timeout | :lifetime_timeout, t) ::
          {:noreply, t()} | {:stop, :normal, t()}
  def handle_info(msg, state) when msg in ~w[inactivity_timeout lifetime_timeout]a do
    with %{name: action_name} <- Resource.Info.primary_action(state.resource, :destroy),
         changeset <- Changeset.for_destroy(state.record, action_name),
         :ok <- state.api.destroy(changeset, return_destroyed?: false) do
      {:noreply, state}
    else
      _ -> {:stop, :normal, state}
    end
  end

  defp primary_key_from_resource_and_changeset(resource, changeset) do
    resource
    |> Resource.Info.primary_key()
    |> Enum.into(%{}, &{&1, Changeset.get_attribute(changeset, &1)})
  end

  defp unload_relationships(resource, record) do
    empty = resource.__struct__

    resource
    |> Resource.Info.relationships()
    |> Enum.reduce(record, fn relationship, record ->
      Map.put(record, relationship.name, Map.get(empty, relationship.name))
    end)
  end

  defp get_config(resource, attr, default),
    do: Extension.get_opt(resource, [:gen_server], attr, default)

  defp maybe_set_inactivity_timer(%{inactivity_timeout: :infinity} = state), do: state

  defp maybe_set_inactivity_timer(%{inactivity_timeout: ttl, inactivity_timer: nil} = state),
    do: %{state | inactivity_timer: Process.send_after(self(), :inactivity_timeout, ttl)}

  defp maybe_set_inactivity_timer(%{inactivity_timer: timer} = state) do
    Process.cancel_timer(timer)
    maybe_set_inactivity_timer(%{state | inactivity_timer: nil})
  end

  defp maybe_set_lifetime_timer(%{maximum_lifetime: :infinity} = state), do: state

  defp maybe_set_lifetime_timer(%{maximum_lifetime: ttl} = state),
    do: %{state | lifetime_timer: Process.send_after(self(), :lifetime_timeout, ttl)}
end
