defmodule GQL do
  @moduledoc """
  Documentation for `GQL`.
  """

  @query_opts_validation [
    variables: [
      type: :any,
      default: [],
      doc: "Keyword list or map of variables."
    ],
    url: [
      type: :string,
      required: true
    ]
  ]

  @doc """
  Queries a GraphQL endpoint.
  """
  def query(query, opts \\ []) do
    {finch_mod, opts} = Keyword.pop(opts, :finch_mod, Finch)

    opts = NimbleOptions.validate!(opts, @query_opts_validation)

    body = %{query: query, variables: Map.new(opts[:variables])}
    headers = [{"content-type", "application/json"}]

    Finch.build(:post, opts[:url], headers, Jason.encode!(body))
    |> finch_mod.request(GQL.Finch, [])
    |> case do
      {:ok, %Finch.Response{status: status} = resp} when status >= 200 and status < 500 ->
        handle_body(Jason.decode!(resp.body), resp.headers)
    end
  end

  defp handle_body(%{"errors" => _} = body, headers) do
    {:error, body, headers}
  end

  defp handle_body(%{} = body, headers) do
    {:ok, body, headers}
  end
end
