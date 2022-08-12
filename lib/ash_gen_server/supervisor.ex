defmodule AshGenServer.Supervisor do
  @moduledoc """
  A DynamicSupervisor which supervises the indivdual resource processes.
  """
  use DynamicSupervisor
  alias Ash.{Changeset, Resource}
  alias AshGenServer.Registry

  @doc false
  @spec start_link(list) :: Supervisor.on_start()
  def start_link(args), do: DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)

  @doc false
  @impl true
  def init(_), do: DynamicSupervisor.init(strategy: :one_for_one)

  @doc """
  Given a resource and a changeset, spawn a new server.
  """
  @spec start_server(Resource.t(), Changeset.t()) :: DynamicSupervisor.on_start_child()
  def start_server(resource, changeset) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {AshGenServer.Server, [resource, changeset]}
    )
  end

  @doc """
  Terminate the the resource and remove it from the supervision tree.
  """
  @spec stop_server(Registry.resource_key()) :: :ok
  def stop_server(resource_key) do
    with {:ok, pid} <- AshGenServer.Registry.find_server_by_resource_key(resource_key),
         do: DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end
