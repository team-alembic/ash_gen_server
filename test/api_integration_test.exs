defmodule AshGenServer.ApiIntegrationTest do
  @moduledoc """
  Integrates the entire API to ensure that it works as advertised.
  """

  use AshGenServer.RuntimeCase
  alias Ash.Changeset

  test "it's the plot of Back to the Future" do
    assert {:ok, einstein} =
             TimeTravel.Character
             |> Changeset.for_create(:create, %{
               name: "Einstein Brown",
               nickname: "Einie",
               current_year: 1985
             })
             |> TimeTravel.create()

    assert {:ok, doc} =
             TimeTravel.Character
             |> Changeset.for_create(:create, %{
               name: "Emmet Lathrop Brown",
               nickname: "Doc",
               current_year: 1985
             })
             |> TimeTravel.create()

    assert {:ok, marty} =
             TimeTravel.Character
             |> Changeset.for_create(:create, %{
               name: "Martin Seamus McFly",
               nickname: "Marty",
               current_year: 1985
             })
             |> TimeTravel.create()

    assert {:ok, jennifer} =
             TimeTravel.Character
             |> Changeset.for_create(:create, %{
               name: "Jennifer Jane Parker",
               nickname: "Jennifer",
               current_year: 1985
             })
             |> TimeTravel.create()

    assert {:ok, %{has_power?: false} = delorean} =
             TimeTravel.Machine
             |> Changeset.for_create(:create, %{
               name: "OUTATIME",
               model: "DMC-12",
               manufacturer: "Delorean Motor Company",
               power_source: "Plutonium"
             })
             |> TimeTravel.create()

    assert {:ok, %{has_power?: true} = delorean} =
             delorean
             |> Changeset.for_update(:charge)
             |> TimeTravel.update()

    assert {:ok, %{has_power?: false} = delorean} =
             delorean
             |> Changeset.for_update(:travel_in_time, %{occupants: [einstein], target_year: 1985})
             |> TimeTravel.update()

    assert {:ok, %{current_year: 1985}} = TimeTravel.reload(einstein)

    assert {:ok, %{has_power?: true} = delorean} =
             delorean
             |> Changeset.for_update(:charge)
             |> TimeTravel.update()

    assert {:ok, %{has_power?: false} = delorean} =
             delorean
             |> Changeset.for_update(:travel_in_time, %{occupants: [marty], target_year: 1955})
             |> TimeTravel.update()

    assert {:ok, %{current_year: 1955} = marty} = TimeTravel.reload(marty)

    {:ok, delorean} =
      delorean
      |> Changeset.for_update(:retrofit, %{power_source: "Lightning"})
      |> TimeTravel.update()

    {:ok, %{has_power?: true} = delorean} =
      delorean
      |> Changeset.for_update(:charge)
      |> TimeTravel.update()

    assert {:ok, %{has_power?: false} = delorean} =
             delorean
             |> Changeset.for_update(:travel_in_time, %{occupants: [marty], target_year: 1985})
             |> TimeTravel.update()

    assert {:ok, %{current_year: 1985} = marty} = TimeTravel.reload(marty)

    {:ok, delorean} =
      delorean
      |> Changeset.for_update(:retrofit, %{power_source: "Mr Fusion"})
      |> TimeTravel.update()

    {:ok, %{has_power?: true} = delorean} =
      delorean
      |> Changeset.for_update(:charge)
      |> TimeTravel.update()

    assert {:ok, %{has_power?: false}} =
             delorean
             |> Changeset.for_update(:travel_in_time, %{
               occupants: [marty, doc, jennifer],
               target_year: 2015
             })
             |> TimeTravel.update()

    assert {:ok, %{current_year: 2015}} = TimeTravel.reload(marty)
    assert {:ok, %{current_year: 2015}} = TimeTravel.reload(doc)
    assert {:ok, %{current_year: 2015}} = TimeTravel.reload(jennifer)
  end
end
