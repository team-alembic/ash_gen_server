defmodule TimeTravel.MachineTravelChange do
  @moduledoc false
  use Ash.Resource.Change
  alias Ash.Changeset

  @impl true
  def change(changeset, _opts, _context) do
    has_power? = Changeset.get_attribute(changeset, :has_power?)

    if has_power? do
      occupants = Changeset.get_argument(changeset, :occupants)
      target_year = Changeset.get_argument(changeset, :target_year)

      changeset
      |> Changeset.change_attribute(:has_power?, false)
      |> Changeset.after_action(fn _changeset, machine ->
        occupants
        |> Enum.reduce_while({:ok, machine}, fn occupant, {:ok, machine} ->
          occupant
          |> Changeset.for_update(:travel_in_time, %{target_year: target_year})
          |> TimeTravel.update()
          |> case do
            {:ok, _} -> {:cont, {:ok, machine}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)
      end)
    else
      changeset
      |> Changeset.add_error(:action, "Power source needs topping up")
    end
  end
end
