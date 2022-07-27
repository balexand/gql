defmodule GQL.Finch.Behaviour do
  @callback request(Finch.Request.t(), Finch.name(), keyword()) ::
              {:ok, Finch.Response.t()} | {:error, Finch.Exception.t()}
end

Mox.defmock(GQL.MockFinch, for: GQL.Finch.Behaviour)
