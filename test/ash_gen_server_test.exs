defmodule AshGenServerTest do
  use ExUnit.Case
  doctest AshGenServer

  test "greets the world" do
    assert AshGenServer.hello() == :world
  end
end
