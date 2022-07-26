defmodule GqlTest do
  use ExUnit.Case
  doctest Gql

  test "greets the world" do
    assert Gql.hello() == :world
  end
end
