defmodule GQLTest do
  use ExUnit.Case, async: true
  doctest GQL

  alias GQL.MockFinch

  @url "https://example.com/graphql"

  @spacex_launch_query """
  query Launch($launch_id: ID!) {
    launch(id: $launch_id) {
      id
      details
    }
  }
  """

  @headers [{"content-type", "application/json; charset=utf-8"}]

  @spacex_resp %Finch.Response{
    body:
      "{\"data\":{\"launches\":[{\"id\":\"13\",\"details\":\"Second GTO launch for Falcon 9. The USAF evaluated launch data from this flight as part of a separate certification program for SpaceX to qualify to fly U.S. military payloads and found that the Thaicom 6 launch had \\\"unacceptable fuel reserves at engine cutoff of the stage 2 second burnoff\\\"\"},{\"id\":\"17\",\"details\":null}]}}\n",
    headers: @headers,
    status: 200
  }

  @spacex_error_resp %Finch.Response{
    body:
      "{\"errors\":[{\"message\":\"Variable \\\"$launch_id\\\" of required type \\\"ID!\\\" was not provided.\",\"locations\":[{\"line\":1,\"column\":14}],\"extensions\":{\"code\":\"INTERNAL_SERVER_ERROR\"}}]}\n",
    headers: [{"content-type", "application/json; charset=utf-8"}],
    status: 400
  }

  @expected_body %{
    "data" => %{
      "launches" => [
        %{
          "details" =>
            "Second GTO launch for Falcon 9. The USAF evaluated launch data from this flight as part of a separate certification program for SpaceX to qualify to fly U.S. military payloads and found that the Thaicom 6 launch had \"unacceptable fuel reserves at engine cutoff of the stage 2 second burnoff\"",
          "id" => "13"
        },
        %{"details" => nil, "id" => "17"}
      ]
    }
  }

  import Mox, only: [verify_on_exit!: 1]
  setup :verify_on_exit!

  test "query" do
    Mox.expect(MockFinch, :request, fn req, GQL.Finch, [receive_timeout: 30000] ->
      assert req == %Finch.Request{
               body:
                 "{\"query\":\"query Launch($launch_id: ID!) {\\n  launch(id: $launch_id) {\\n    id\\n    details\\n  }\\n}\\n\",\"variables\":{}}",
               headers: [{"content-type", "application/json"}, {"X-Shopify-Access-Token", "🐓"}],
               host: "example.com",
               method: "POST",
               path: "/graphql",
               port: 443,
               query: nil,
               scheme: :https
             }

      {:ok, @spacex_resp}
    end)

    assert {:ok, @expected_body, @headers} ==
             GQL.query(@spacex_launch_query,
               finch_mod: MockFinch,
               headers: [{"X-Shopify-Access-Token", "🐓"}],
               url: @url
             )
  end

  test "query with GraphQL error" do
    Mox.expect(MockFinch, :request, fn _, _, _ ->
      {:ok, @spacex_error_resp}
    end)

    assert {:error, %{"errors" => [%{}]}, [_ | _]} =
             GQL.query(@spacex_launch_query, finch_mod: MockFinch, url: @url)
  end

  test "query without required opts" do
    assert_raise NimbleOptions.ValidationError,
                 "required option :url not found, received options: [:variables, :http_options, :headers, :finch_mod]",
                 fn ->
                   GQL.query(@spacex_launch_query, [])
                 end
  end

  test "query with HTTP 500 error" do
    Mox.expect(MockFinch, :request, fn _, _, _ ->
      {:ok, %Finch.Response{body: "boom", headers: [], status: 500}}
    end)

    assert_raise GQL.ServerError, "Server responded with HTTP status: 500", fn ->
      GQL.query(@spacex_launch_query, finch_mod: MockFinch, url: @url)
    end
  end

  test "query!" do
    Mox.expect(MockFinch, :request, fn _, _, _ ->
      {:ok, @spacex_resp}
    end)

    assert {@expected_body, @headers} ==
             GQL.query!(@spacex_launch_query, finch_mod: MockFinch, url: @url)
  end

  test "query! with GraphQL error" do
    Mox.expect(MockFinch, :request, fn _, _, _ ->
      {:ok, @spacex_error_resp}
    end)

    assert_raise GQL.GraphQLError,
                 "%GQL.GraphQLError{body: %{\"errors\" => [%{\"extensions\" => %{\"code\" => \"INTERNAL_SERVER_ERROR\"}, \"locations\" => [%{\"column\" => 14, \"line\" => 1}], \"message\" => \"Variable \\\"$launch_id\\\" of required type \\\"ID!\\\" was not provided.\"}]}}",
                 fn ->
                   GQL.query!(@spacex_launch_query, finch_mod: MockFinch, url: @url)
                 end
  end
end
