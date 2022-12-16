# AshGenServer

An Ash Datalayer backed by individual GenServers.

This package provides an
[`Ash.DataLayer`](https://ash-hq.org/docs/module/ash/latest/ash-datalayer) which
stores resources in emphemeral GenServers.  The main use-case for this is two fold:

  1. Ability to automatically remove resources after an inactivity timeout.
  2. (Potential) ability to migrate resources across a cluster during deploys to
     allow access to continue without failure.
  3. before and after hooks for changesets and queries are run within the server
     process, making registration, etc, possible.

## Caveats

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

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ash_gen_server` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ash_gen_server, "~> 0.3.0"}
  ]
end
```

## Usage

This package assumes that you have [Ash](https://ash-hq.org) installed and
configured.  See the Ash documentation for details.

Once installed you can easily define a resource which is backed by a GenServer:

```elixir
defmodule MyApp.EphemeralResource do
  use Ash.Resource, data_layer: AshGenServer.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :temporary_data, :string
  end
end
```

## Documentation

Documentation for the latest release will be [available on
hexdocs](https://hexdocs.pm/ash_gen_server) and for the [`main`
branch](https://team-alembic.github.io/ash_gen_server).

## Contributing

  * To contribute updates, fixes or new features please fork and open a
    pull-request against `main`.
  * Please use [conventional
    commits](https://www.conventionalcommits.org/en/v1.0.0/) - this allows us to
    dynamically generate the changelog.
  * Feel free to ask any questions on out [GitHub discussions
    page](https://github.com/team-alembic/ash_gen_server/discussions).

