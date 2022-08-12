defmodule AshGenServer.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :ash_gen_server,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      consolidate_protocols: Mix.env() != :test
    ]
  end

  def package do
    [
      maintainers: [
        "James Harton <james.harton@alembic.com.au>"
      ],
      licenses: ["MIT"],
      links: %{
        "Source" => "https://github.com/team-alembic/ash_gen_server"
      },
      source_url: "https://github.com/team-alembic/ash_gen_server"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AshGenServer.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ash, "~> 1.53"},
      {:credo, "~> 1.6", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: [:dev, :test]},
      {:doctor, "~> 0.18", only: [:dev, :test]},
      {:git_ops, "~> 2.4", only: [:dev, :test], runtime: false}
    ]
  end
end
