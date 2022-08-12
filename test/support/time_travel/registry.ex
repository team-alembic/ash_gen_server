defmodule TimeTravel.Registry do
  @moduledoc false
  use Ash.Registry, extensions: [Ash.Registry.ResourceValidations]

  entries do
    entry TimeTravel.Character
    entry TimeTravel.Machine
  end
end
