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

  @spacex_resp %Finch.Response{
    body:
      "{\"data\":{\"launches\":[{\"id\":\"13\",\"details\":\"Second GTO launch for Falcon 9. The USAF evaluated launch data from this flight as part of a separate certification program for SpaceX to qualify to fly U.S. military payloads and found that the Thaicom 6 launch had \\\"unacceptable fuel reserves at engine cutoff of the stage 2 second burnoff\\\"\"},{\"id\":\"17\",\"details\":null}]}}\n",
    headers: [
      {"content-type", "application/json; charset=utf-8"}
    ],
    status: 200
  }

  import Mox, only: [verify_on_exit!: 1]
  setup :verify_on_exit!

  test "query without required opts" do
    Mox.expect(MockFinch, :request, fn _, _, _ ->
      {:ok, @spacex_resp}
    end)

    assert {:ok, body, headers} = GQL.query(@spacex_launch_query, finch_mod: MockFinch, url: @url)

    assert headers == [{"content-type", "application/json; charset=utf-8"}]

    assert body == %{
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
  end
end
