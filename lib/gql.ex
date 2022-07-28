defmodule GQL do
  @moduledoc """
  Simple GraphQL client.
  """

  defmodule ConnectionError do
    @moduledoc """
    Error raised when a connection error occurs. See `Mint.TransportError` for list of possible
    values for the `reason` field.
    """

    defexception [:reason]

    def message(exception) do
      inspect(exception)
    end
  end

  defmodule GraphQLError do
    @moduledoc """
    Error raised when response contains GraphQL errors.
    """

    defexception [:body]

    def message(exception), do: inspect(exception)
  end

  defmodule ServerError do
    @moduledoc """
    Error raised when server returns 5xx HTTP status code.
    """

    defexception [:response, :status]

    def message(exception), do: "Server responded with HTTP status: #{exception.status}"
  end

  @query_opts_validation [
    finch_mod: [
      type: :atom,
      default: Finch,
      doc: false
    ],
    headers: [
      type: {:list, :any},
      default: [],
      doc: "HTTP headers to include."
    ],
    http_options: [
      type: :keyword_list,
      doc: "Options to be passed to `Finch.request/3`.",
      default: [receive_timeout: 30_000]
    ],
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
  def query!(query, opts) do
    case query(query, opts) do
      {:ok, body, headers} -> {body, headers}
      {:error, body, _headers} -> raise %GraphQLError{body: body}
    end
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
  def query(query, opts) do
    opts = NimbleOptions.validate!(opts, @query_opts_validation)

    body = %{query: query, variables: Map.new(opts[:variables])}
    headers = [{"content-type", "application/json"}] ++ opts[:headers]

    Finch.build(:post, opts[:url], headers, Jason.encode!(body))
    |> opts[:finch_mod].request(GQL.Finch, opts[:http_options])
    |> case do
      {:ok, %Finch.Response{status: status} = resp} when status >= 200 and status < 500 ->
        handle_body(Jason.decode!(resp.body), resp.headers)

      {:ok, %Finch.Response{} = resp} ->
        raise %ServerError{response: resp, status: resp.status}

      {:error, %Mint.TransportError{reason: reason}} ->
        raise %ConnectionError{reason: reason}
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
