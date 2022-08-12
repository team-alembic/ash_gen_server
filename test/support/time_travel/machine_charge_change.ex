defmodule TimeTravel.MachineChargeChange do
  @moduledoc false
  use Ash.Resource.Change
  alias Ash.Changeset

  @impl true
  def change(changeset, _opts, _context) do
    changeset
    |> Changeset.change_attribute(:has_power?, true)
  end
end
