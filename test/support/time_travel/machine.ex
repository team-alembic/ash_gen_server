defmodule TimeTravel.Machine do
  @moduledoc false
  use Ash.Resource, data_layer: AshGenServer.DataLayer

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          name: String.t(),
          model: String.t(),
          manufacturer: String.t(),
          power_source: String.t(),
          has_power?: boolean,
          created_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  actions do
    create :create

    read :read do
      primary? true
    end

    destroy :destroy

    update :travel_in_time do
      argument :occupants, {:array, TimeTravel.Character}
      argument :target_year, :integer, allow_nil?: false
      change TimeTravel.MachineTravelChange
    end

    update :retrofit do
      argument :power_source, :string, allow_nil?: false
      change TimeTravel.MachineRetrofitChange
    end

    update :charge do
      change TimeTravel.MachineChargeChange
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false
    attribute :model, :string
    attribute :manufacturer, :string
    attribute :power_source, :string
    attribute :has_power?, :boolean, allow_nil?: false, default: false

    create_timestamp :created_at
    update_timestamp :updated_at
  end
end
