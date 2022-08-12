defmodule AshGenServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

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
