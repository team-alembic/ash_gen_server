defmodule TimeTravel.Character do
  @moduledoc false
  use Ash.Resource, data_layer: AshGenServer.DataLayer

  actions do
    create :create

    read :read do
      primary? true
    end

    destroy :destroy

    update :travel_in_time do
      argument :target_year, :integer, allow_nil?: false

      change TimeTravel.CharacterTravelChange
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false
    attribute :nickname, :string
    attribute :current_year, :integer, allow_nil?: false

    create_timestamp :created_at
    update_timestamp :updated_at
  end
end
