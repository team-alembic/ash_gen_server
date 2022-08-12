defmodule AshGenServer.DataLayerTest do
  @moduledoc false
  use AshGenServer.RuntimeCase

  alias Ash.{Changeset, Filter}
  alias AshGenServer.{DataLayer, Query, Registry, Server}

  describe "create/2" do
    test "it spawns and registers a new process" do
      changeset =
        TimeTravel.Character
        |> Changeset.for_create(:create, %{
          name: "Martin Seamus McFly",
          nickname: "Marty",
          current_year: 1985
        })

      assert {:ok, %TimeTravel.Character{id: id}} =
               DataLayer.create(TimeTravel.Character, changeset)

      assert [{{TimeTravel.Character, %{id: ^id}}, pid}] = Registry.find_servers()

      assert {:ok, %{nickname: "Marty"}} = Server.get(pid)
    end
  end

  describe "update/2" do
    test "when a resource exists, it updates it" do
      assert {:ok, doc} =
               TimeTravel.Character
               |> Changeset.for_create(:create, %{
                 name: "Emmet Lathrop Brown",
                 nickname: "Doc",
                 current_year: 1985
               })
               |> TimeTravel.create()

      changeset = doc |> Changeset.for_update(:travel_in_time, %{target_year: 1955})

      assert {:ok, %{current_year: 1955}} = DataLayer.update(TimeTravel.Character, changeset)

      {:ok, pid} = Registry.find_server_by_resource_key({TimeTravel.Character, %{id: doc.id}})
      assert {:ok, %{current_year: 1955}} = Server.get(pid)
    end

    test "when a resource doesn't exist, it returns an error" do
      changeset =
        %TimeTravel.Character{
          id: Ecto.UUID.generate(),
          name: "Emmet Lathrop Brown",
          nickname: "Doc",
          current_year: 1985
        }
        |> Changeset.for_update(:travel_in_time, %{target_year: 1955})

      assert {:error, :not_found} = DataLayer.update(TimeTravel.Character, changeset)
    end
  end

  describe "destroy/2" do
    test "when a resource exists, it stops the process" do
      assert {:ok, doc} =
               TimeTravel.Character
               |> Changeset.for_create(:create, %{
                 name: "Emmet Lathrop Brown",
                 nickname: "Doc",
                 current_year: 1985
               })
               |> TimeTravel.create()

      changeset = doc |> Changeset.for_destroy(:destroy)
      {:ok, pid} = Registry.find_server_by_resource_key({TimeTravel.Character, %{id: doc.id}})

      assert :ok = DataLayer.destroy(TimeTravel.Character, changeset)

      refute Process.alive?(pid)
    end

    test "when a resource doesn't exist, it returns an error" do
      changeset =
        %TimeTravel.Character{
          id: Ecto.UUID.generate(),
          name: "Emmet Lathrop Brown",
          nickname: "Doc",
          current_year: 1985
        }
        |> Changeset.for_destroy(:destroy)

      assert {:error, :not_found} = DataLayer.destroy(TimeTravel.Character, changeset)
    end
  end

  describe "resource_to_query/2" do
    test "it returns a new empty query" do
      assert %Query{
               resource: TimeTravel.Machine,
               api: TimeTravel,
               filter: nil,
               limit: nil,
               offset: nil,
               sort: nil
             } = DataLayer.resource_to_query(TimeTravel.Machine, TimeTravel)
    end
  end

  describe "filter/3" do
    test "when the existing query contains no filter, it adds it" do
      query = DataLayer.resource_to_query(TimeTravel.Machine, TimeTravel)

      filter =
        TimeTravel.Machine
        |> Ash.Query.filter(name: "OUTATIME")
        |> Map.fetch!(:filter)

      assert {:ok, %{filter: ^filter}} = DataLayer.filter(query, filter, TimeTravel.Machine)
    end

    test "when the existing query contains a filter, it combines them" do
      query =
        TimeTravel.Machine
        |> DataLayer.resource_to_query(TimeTravel)

      filter =
        TimeTravel.Machine
        |> Ash.Query.filter(name: "OUTATIME")
        |> Map.fetch!(:filter)

      {:ok, query} = DataLayer.filter(query, filter, TimeTravel.Machine)

      filter =
        TimeTravel.Machine
        |> Ash.Query.filter(model: "DMC-12")
        |> Map.fetch!(:filter)

      assert {:ok, %{filter: filter}} = DataLayer.filter(query, filter, TimeTravel.Machine)

      assert "OUTATIME" = Filter.find_simple_equality_predicate(filter, :name)
      assert "DMC-12" = Filter.find_simple_equality_predicate(filter, :model)
    end
  end

  describe "limit/3" do
    test "it adds the limit to the query" do
      query =
        TimeTravel.Machine
        |> DataLayer.resource_to_query(TimeTravel)

      assert {:ok, %{limit: 13}} = DataLayer.limit(query, 13, TimeTravel.Machine)
    end
  end

  describe "offset/3" do
    test "it adds the offset to the query" do
      query =
        TimeTravel.Machine
        |> DataLayer.resource_to_query(TimeTravel)

      assert {:ok, %{offset: 13}} = DataLayer.offset(query, 13, TimeTravel.Machine)
    end
  end

  describe "sort/3" do
    test "it adds the sort to the query" do
      query =
        TimeTravel.Machine
        |> DataLayer.resource_to_query(TimeTravel)

      assert {:ok, %{sort: [:name]}} = DataLayer.sort(query, [:name], TimeTravel.Machine)
    end
  end

  describe "run_query/2" do
    setup :with_character_fixtures

    test "when retrieving an existing record by the primary key, it works", %{doc: doc} do
      filter = Ash.Query.filter(TimeTravel.Character, id: doc.id).filter

      {:ok, query} =
        TimeTravel.Character
        |> DataLayer.resource_to_query(TimeTravel)
        |> DataLayer.filter(filter, TimeTravel.Character)

      assert {:ok, [^doc]} = DataLayer.run_query(query, TimeTravel.Character)
    end

    test "when retrieving a non-existant record by the primary key, it returns an empty list" do
      filter = Ash.Query.filter(TimeTravel.Character, id: Ecto.UUID.generate()).filter

      {:ok, query} =
        TimeTravel.Character
        |> DataLayer.resource_to_query(TimeTravel)
        |> DataLayer.filter(filter, TimeTravel.Character)

      assert {:ok, []} = DataLayer.run_query(query, TimeTravel.Character)
    end

    test "it can filter by arbitrary fields" do
      filter = Ash.Query.filter(TimeTravel.Character, nickname: "Marty").filter

      {:ok, query} =
        TimeTravel.Character
        |> DataLayer.resource_to_query(TimeTravel)
        |> DataLayer.filter(filter, TimeTravel.Character)

      assert {:ok, result} = DataLayer.run_query(query, TimeTravel.Character)
      assert ["Marty"] = Enum.map(result, & &1.nickname)
    end

    test "it can sort by arbitrary fields" do
      {:ok, query} =
        TimeTravel.Character
        |> DataLayer.resource_to_query(TimeTravel)
        |> DataLayer.sort([name: :desc], TimeTravel.Character)

      assert {:ok, result} = DataLayer.run_query(query, TimeTravel.Character)

      assert ["Marty", "Doc"] = Enum.map(result, & &1.nickname)
    end

    test "it can offset an arbitrary number of results" do
      {:ok, query} =
        TimeTravel.Character
        |> DataLayer.resource_to_query(TimeTravel)
        |> DataLayer.sort([name: :asc], TimeTravel.Character)

      {:ok, query} = DataLayer.offset(query, 1, TimeTravel.Character)

      assert {:ok, result} = DataLayer.run_query(query, TimeTravel.Character)

      assert ["Marty"] = Enum.map(result, & &1.nickname)
    end

    test "it can limit to an arbitrary number of results" do
      {:ok, query} =
        TimeTravel.Character
        |> DataLayer.resource_to_query(TimeTravel)
        |> DataLayer.sort([name: :asc], TimeTravel.Character)

      {:ok, query} = DataLayer.limit(query, 1, TimeTravel.Character)

      assert {:ok, result} = DataLayer.run_query(query, TimeTravel.Character)

      assert ["Doc"] = Enum.map(result, & &1.nickname)
    end
  end

  def with_character_fixtures(_) do
    {:ok, doc} =
      TimeTravel.Character
      |> Changeset.for_create(:create, %{
        name: "Emmet Lathrop Brown",
        nickname: "Doc",
        current_year: 1985
      })
      |> TimeTravel.create()

    {:ok, marty} =
      TimeTravel.Character
      |> Changeset.for_create(:create, %{
        name: "Martin Seamus McFly",
        nickname: "Marty",
        current_year: 1985
      })
      |> TimeTravel.create()

    {:ok, doc: doc, marty: marty}
  end
end
