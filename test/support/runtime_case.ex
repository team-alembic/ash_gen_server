defmodule AshGenServer.RuntimeCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  alias AshGenServer.{Registry, Supervisor}

  setup do
    {:ok, registry_pid} = Registry.start_link([])
    {:ok, supervisor_pid} = Supervisor.start_link([])

    on_exit(fn ->
      await_exit(registry_pid)
      await_exit(supervisor_pid)
    end)

    :ok
  end

  using do
    quote do
      require Ash.Query
    end
  end

  defp await_exit(pid) do
    Process.monitor(pid)
    Process.exit(pid, :normal)

    receive do
      {:DOWN, _, :process, ^pid, _} -> :ok
    after
      5000 -> :error
    end
  end
end
