defmodule AshGenServer.Query do
  @moduledoc """
  A struct which holds information about a resource query as it is being built.
  """
  defstruct [:resource, :filter, :api, :limit, :offset, :sort]

  @type t :: %__MODULE__{
          resource: Ash.Resource.t(),
          filter: Ash.Filter.t(),
          api: Ash.Api.t(),
          limit: non_neg_integer(),
          offset: non_neg_integer(),
          sort: Ash.Sort.t()
        }
end
