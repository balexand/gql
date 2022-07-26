defmodule GQL do
  @moduledoc """
  Simple GraphQL client.
  """

  @query_opts_validation [
    variables: [
      type: :any,
      default: [],
      doc: "Keyword list or map of variables."
    ],
    url: [
      type: :string,
      required: true,
      doc: "URL to which the request is made."
    ]
  ]

  @doc """
  Like `query/2`, except raises `GQL.GraphQLError` if the server returns errors.
  """
  def query!(_query, _opts \\ []) do
    # FIXME
  end

  @doc """
  Queries a GraphQL endpoint. Returns `{:ok, body, headers}` upon success or `{:error, body,
  headers}` if the response contains an "errors" key.

  An exception will be raised for exceptional errors:

  * `GQL.ConnectionError` if the HTTP client returns a connection error such as a timeout.
  * `GQL.ServerError` if the server responded with a 5xx code.

  ## Options

  #{NimbleOptions.docs(@query_opts_validation)}
  """
  def query(query, opts \\ []) do
    # FIXME http_options
    # FIXME exception types

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
    # Return error if response body contains errors. In this case the HTTP status is inconsistent
    # between different APIs. Github and SpaceX return errors with HTTP 200 status. Shopify
    # returns errors with HTTP 400 status.
    {:error, body, headers}
  end

  defp handle_body(%{} = body, headers) do
    {:ok, body, headers}
  end
end
