defmodule AshGenServer.Query do
  @moduledoc """
  A struct which holds information about a resource query as it is being built.
  """
  defstruct [:resource, :filter, :api, :limit, :offset, :sort]

  @type t :: %__MODULE__{
          resource: Ash.Resource.t(),
          filter: nil | Ash.Filter.t(),
          api: Ash.Api.t(),
          limit: nil | non_neg_integer(),
          offset: nil | non_neg_integer(),
          sort: nil | Ash.Sort.t()
        }
end
