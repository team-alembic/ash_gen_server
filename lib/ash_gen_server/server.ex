defmodule AshGenServer.Server do
  @moduledoc """
  The main resource server.

  This module is a `GenServer` which can create, read and update a single
  resource stored within it's state by applying changesets.
  """
  defstruct ~w[primary_key resource record]a
  alias Ash.{Changeset, Resource}
  alias AshGenServer.Registry
  use GenServer

  @type t :: %__MODULE__{
          primary_key: Registry.primary_key(),
          resource: Resource.t(),
          record: Resource.record()
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
  @spec init(list) :: {:ok, t} | {:error, any}
  def init([resource, changeset]) do
    primary_key = primary_key_from_resource_and_changeset(resource, changeset)

    with {:ok, _self} <- Registry.register({resource, primary_key}),
         {:ok, record} <- Changeset.apply_attributes(changeset) do
      record = unload_relationships(resource, record)
      {:ok, %__MODULE__{primary_key: primary_key, resource: resource, record: record}}
    else
      {:error, {:already_registered, _}} -> {:stop, :already_exists}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc false
  @impl true
  @spec handle_call(:get | {:update, Resource.t(), Changeset.t()}, GenServer.from(), t) ::
          {:reply, {:ok, Resource.record()} | {:error, any}, t}
  def handle_call(:get, _from, state), do: {:reply, {:ok, state.record}, state}

  def handle_call({:update, resource, changeset}, _from, state) when state.resource == resource do
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
end
