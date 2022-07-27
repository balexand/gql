defmodule GQL.IntegrationTest do
  @moduledoc """
  Tests that make real requests to the SpaceX GraphQL API. Run these tests with:

      mix test --include integration
  """

  use ExUnit.Case, async: true

  @moduletag :integration

  @spacex_url "https://api.spacex.land/graphql/"

  @spacex_list_launches_query """
  query Launches {
    launches(limit: 2) {
      id
      details
    }
  }
  """

  @spacex_launch_query """
  query Launch($launch_id: ID!) {
    launch(id: $launch_id) {
      id
      details
    }
  }
  """

  test "SpaceX list launches" do
    assert {:ok, body, [_ | _]} = GQL.query(@spacex_list_launches_query, url: @spacex_url)

    assert %{"data" => %{"launches" => [%{"details" => _, "id" => _}, %{}]}} = body
  end

  test "SpaceX get launch by id" do
    assert {:ok, body, [_ | _]} =
             GQL.query(@spacex_launch_query, variables: [launch_id: "9"], url: @spacex_url)

    assert body == %{
             "data" => %{
               "launch" => %{
                 "details" =>
                   "CRS-1 successful, but the secondary payload was inserted into abnormally low orbit and lost due to Falcon 9 boost stage engine failure, ISS visiting vehicle safety rules, and the primary payload owner's contractual right to decline a second ignition of the second stage under some conditions.",
                 "id" => "9"
               }
             }
           }
  end

  test "SpaceX timeout" do
    exception =
      assert_raise(GQL.ConnectionError, "%GQL.ConnectionError{reason: :timeout}", fn ->
        GQL.query(@spacex_launch_query,
          http_options: [receive_timeout: 1],
          variables: [launch_id: "9"],
          url: @spacex_url
        )
      end)

    assert exception.reason == :timeout
  end

  test "SpaceX get launch with missing id variable" do
    assert {:error, body, [_ | _]} = GQL.query(@spacex_launch_query, url: @spacex_url)

    assert %{
             "errors" => [
               %{
                 "extensions" => %{"code" => "INTERNAL_SERVER_ERROR"},
                 "locations" => [%{"column" => 14, "line" => 1}],
                 "message" => "Variable \"$launch_id\" of required type \"ID!\" was not provided."
               }
             ]
           } = body
  end
end
