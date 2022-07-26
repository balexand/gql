# GQL

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

TODO

## Alternatives

Please submit pull-requests if you know of any others.

### [`absinthe_client`](https://github.com/absinthe-graphql/absinthe_client)

The README indicates this project is not ready for use and it hasn't seen commits since 2019.

### [`neuron`](https://github.com/uesteibar/neuron)

Neuron is a great library and I have successfully used it in production. But there are several small issues that have lead me to create this library:

* The handling of fragments in `Neuron.Fragment` is flawed. All fragments are registered either globally using `Application.put_env/3` or per-process using `Process.put/2`. It would be easy for two different client libraries to overwrite each others' fragments and cause surprising and hard to diagnose bugs. `Application.put_env/3` is intended for configuration and I don't think that it should ever be used as a hack to create global variables.
* Neuron does not always return descriptive errors. For example, when an API endpoint returns an HTTP status of 500 with HTML in the body (like Shopify) then `Neuron.JSONParseError` is returned as opposed to an error that indicates 500 error. This makes the errors more cryptic and harder for apps like sentry.io to categorize.
* I prefer [`finch`](https://github.com/sneako/finch) over [`httpoison`](https://github.com/edgurgel/httpoison).
