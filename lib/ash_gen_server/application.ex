defmodule AshGenServer.Application do
  @moduledoc false

  use Application

  @doc false
  @impl true
  def start(_type, _args) do
    children()
    |> Supervisor.start_link(strategy: :one_for_all, name: __MODULE__)
  end

  defp children do
    if Application.get_env(:ash_gen_server, :runtime, true),
      do: [AshGenServer.Supervisor, AshGenServer.Registry],
      else: []
  end
end
