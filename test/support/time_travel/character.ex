defmodule TimeTravel.Character do
  @moduledoc false
  use Ash.Resource, data_layer: AshGenServer.DataLayer

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          name: String.t(),
          nickname: String.t(),
          current_year: integer,
          created_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  actions do
    create(:create)

    read :read do
      primary?(true)
    end

    destroy(:destroy)

    update :travel_in_time do
      argument(:target_year, :integer, allow_nil?: false)

      change(TimeTravel.CharacterTravelChange)
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:name, :string, allow_nil?: false)
    attribute(:nickname, :string)
    attribute(:current_year, :integer, allow_nil?: false)

    create_timestamp(:created_at)
    update_timestamp(:updated_at)
  end

  gen_server do
    inactivity_timeout(:timer.minutes(1))
  end
end
