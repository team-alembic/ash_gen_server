defmodule AshGenServer.RegistryTest do
  @moduledoc false
  use AshGenServer.RuntimeCase
  alias AshGenServer.Registry

  describe "register/1" do
    test "it can register a process" do
      key = {__MODULE__, %{id: Ecto.UUID.generate()}}

      self = self()
      assert {:ok, _} = Registry.register(key)
      assert {:ok, ^self} = Registry.find_server_by_resource_key(key)
    end
  end

  describe "unregister/1" do
    test "it can unregister a process" do
      key = {__MODULE__, %{id: Ecto.UUID.generate()}}

      assert {:ok, _} = Registry.register(key)
      assert :ok = Registry.unregister(key)

      assert {:error, :not_found} = Registry.find_server_by_resource_key(key)
    end
  end

  describe "find_server_by_resource_key/1" do
    test "when given the key of a registered process, it returns the pid" do
      key = {__MODULE__, %{id: Ecto.UUID.generate()}}

      self = self()
      assert {:ok, _} = Registry.register(key)
      assert {:ok, ^self} = Registry.find_server_by_resource_key(key)
    end

    test "when given the key of a non-registered process, it returns a not found error" do
      key = {__MODULE__, %{id: Ecto.UUID.generate()}}
      assert {:error, :not_found} = Registry.find_server_by_resource_key(key)
    end
  end

  describe "find_servers_by_resource/1" do
    test "when there are processes registered for the resource, it returns a list of them" do
      no_of_resoruces = :rand.uniform(7) + 2
      primary_keys = Enum.map(1..no_of_resoruces, fn _ -> %{id: Ecto.UUID.generate()} end)

      for primary_key <- primary_keys do
        Registry.register({__MODULE__, primary_key})
      end

      result = Registry.find_servers_by_resource(__MODULE__)
      assert Enum.count(result) == no_of_resoruces

      for primary_key <- primary_keys do
        assert {primary_key, self()} in result
      end
    end
  end

  describe "find_servers/0" do
    test "it returns a list of all registered processes" do
      no_of_resoruces = :rand.uniform(7) + 2
      primary_keys = Enum.map(1..no_of_resoruces, fn _ -> %{id: Ecto.UUID.generate()} end)

      for primary_key <- primary_keys do
        Registry.register({__MODULE__, primary_key})
      end

      result = Registry.find_servers()
      assert Enum.count(result) == no_of_resoruces

      for primary_key <- primary_keys do
        assert {{__MODULE__, primary_key}, self()} in result
      end
    end
  end
end
