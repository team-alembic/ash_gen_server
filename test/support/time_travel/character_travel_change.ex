defmodule TimeTravel.CharacterTravelChange do
  @moduledoc false
  use Ash.Resource.Change
  alias Ash.Changeset

  @impl true
  def change(changeset, _opts, _context) do
    target_year = Changeset.get_argument(changeset, :target_year)

    changeset
    |> Changeset.change_attribute(:current_year, target_year)
  end
end
