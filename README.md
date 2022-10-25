# AshGenServer

An Ash Datalayer backed by individual GenServers.

If you want in-memory storage of resources then take a look at
`Ash.DataLayer.Ets`.

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
    {:ash_gen_server, "~> 0.2.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ash_gen_server>.

