defmodule TimeTravel do
  @moduledoc """
  An example Ash API that has GenServer backed resources.
  """
  use Ash.Api, otp_app: :ash_gen_server

  resources do
    registry TimeTravel.Registry
  end
end
