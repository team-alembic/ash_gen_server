defmodule AshGenServer.Registry do
  @moduledoc """
  A `Registry` which keeps track of the resources which are currently in use in
  the system.
  """

  @doc false
  @spec child_spec(keyword) :: Supervisor.child_spec()
  def child_spec(opts),
    do: %{id: {Registry, __MODULE__}, start: {__MODULE__, :start_link, [opts]}}

  @typedoc """
  A composite key containing the resource module and the primary key(s).

  This is the key that's actually stored in the Registry.
  """
  @type resource_key :: {Ash.Resource.t(), primary_key}

  @typedoc """
  A map containing the primary key field(s) and value(s) for a the resource.
  """
  @type primary_key :: %{required(atom) => any}

  @doc false
  @spec start_link(keyword) :: {:ok, pid} | {:error, any}
  def start_link(_), do: Registry.start_link(keys: :unique, name: __MODULE__)

  @doc """
  Register the calling process with the provided `resource_key`.
  """
  @spec register(resource_key) :: {:ok, pid} | {:error, {:already_registered, pid}}
  def register(resource_key), do: Registry.register(__MODULE__, resource_key, nil)

  @doc """
  Unregister the calling process from the provided `resource_key`.
  """
  @spec unregister(resource_key) :: :ok
  def unregister(resource_key), do: Registry.unregister(__MODULE__, resource_key)

  @doc """
  Attempt to find a process registered to the provided `resource_key`.
  """
  @spec find_server_by_resource_key(resource_key) :: {:ok, pid} | {:error, :not_found}
  def find_server_by_resource_key(resource_key) do
    case Registry.lookup(__MODULE__, resource_key) do
      [{pid, _}] -> {:ok, pid}
      _ -> {:error, :not_found}
    end
  end

  @doc """
  Find all the processes registered to the provided resource.
  """
  @spec find_servers_by_resource(Ash.Resource.t()) :: [{primary_key, pid}]
  def find_servers_by_resource(resource) do
    Registry.select(__MODULE__, [
      {
        {{resource, :"$1"}, :"$2", :_},
        [],
        [{{:"$1", :"$2"}}]
      }
    ])
  end

  @doc """
  Find all servers currently active.
  """
  @spec find_servers :: [{resource_key, pid}]
  def find_servers do
    Registry.select(__MODULE__, [
      {
        {:"$1", :"$2", :_},
        [],
        [{{:"$1", :"$2"}}]
      }
    ])
  end
end
