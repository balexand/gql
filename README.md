# GQL

[![Package](https://img.shields.io/badge/-Package-important)](https://hex.pm/packages/gql) [![Documentation](https://img.shields.io/badge/-Documentation-blueviolet)](https://hexdocs.pm/gql)

Simple GraphQL client for Elixir.

## Installation

The package can be installed by adding `gql` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gql, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
url = "https://api.spacex.land/graphql/"

# List SpaceX launches
GQL.query("query Launches { launches { id } }", url: url)

# Get SpaceX launch by ID
GQL.query("query Launch($launch_id: ID!) { launch(id: $launch_id) { details } }",
  url: url,
  variables: [launch_id: "9"]
)
```

See [`GQL` docs](https://hexdocs.pm/gql/GQL.html) for details.

## Fragments

This library does not support GraphQL fragments. I'm open to pull-requests but this is not something that is a priority to me.

## Alternatives

Please submit an issue or pull-request if you know of any other GraphQL client libraries for Elixir.

### [`absinthe_client`](https://github.com/absinthe-graphql/absinthe_client)

The README indicates this project is not ready for use and it hasn't seen commits since 2019.

### [`neuron`](https://github.com/uesteibar/neuron)

Neuron is a great library and I have successfully used it in production. But there are a few issues that have lead me to create GQL instead:

* There are serious problems in how fragments are handled in `Neuron.Fragment`. All fragments are registered either globally using `Application.put_env/3` or per-process using `Process.put/2`. It would be easy for two different client libraries to overwrite each others' fragments and cause surprising and hard to find bugs.
* Neuron does not always return descriptive errors. For example, when an API endpoint returns an HTTP status of 500 with HTML in the body (like Shopify) then `Neuron.JSONParseError` is returned as opposed to an error that indicates 500 error. This makes the errors more cryptic and harder for apps like sentry.io to categorize.
* I prefer [`finch`](https://github.com/sneako/finch) over [`httpoison`](https://github.com/edgurgel/httpoison).
