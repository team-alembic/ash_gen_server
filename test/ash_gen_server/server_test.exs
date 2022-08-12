defmodule AshGenServer.ServerTest do
  @moduledoc false
  use AshGenServer.RuntimeCase
  alias Ash.Changeset
  alias AshGenServer.{Registry, Server}

  describe "init/1" do
    test "it registers itself using the primary key provided" do
      changeset =
        TimeTravel.Character
        |> Changeset.for_create(:create, %{name: "Biff Tannen", current_year: 2015})

      id = Changeset.get_attribute(changeset, :id)

      Server.init([TimeTravel.Character, changeset])

      self = self()

      assert {:ok, ^self} =
               Registry.find_server_by_resource_key({TimeTravel.Character, %{id: id}})
    end

    test "it returns the correct state" do
      changeset =
        TimeTravel.Character
        |> Changeset.for_create(:create, %{name: "Biff Tannen", current_year: 2015})

      id = Changeset.get_attribute(changeset, :id)

      assert {:ok, state} = Server.init([TimeTravel.Character, changeset])

      assert state.primary_key == %{id: id}
      assert state.resource == TimeTravel.Character
      assert %TimeTravel.Character{} = state.record
      assert state.record.id == id
      assert state.record.name == "Biff Tannen"
      assert state.record.current_year == 2015
      refute state.record.nickname
    end
  end
end
