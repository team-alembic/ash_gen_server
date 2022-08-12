defmodule TimeTravel.MachineRetrofitChange do
  @moduledoc false
  use Ash.Resource.Change
  alias Ash.Changeset

  @impl true
  def change(changeset, _opts, _context) do
    power_source = Changeset.get_argument(changeset, :power_source)

    changeset
    |> Changeset.change_attribute(:power_source, power_source)
  end
end
