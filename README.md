# Transchange

It's a library that allows for creating a set of Ecto changesets that will run
in a single transaction.

## Example

```elixir
result =
  Transchange.new
  |> Transchange.update(:user, User.changeset(%User{}, user_params))
  |> Transchange.insert(:log, LogEntry.user_created_changeset(user_params))
  |> Transchange.delete(:old_user, old_user)
  |> Transchange.run(MyRepo)

case result do
  {:ok, models} ->
    # models == [user: ..., log: ..., old_user: ...]
  {:error, changesets} ->
    # changesets == [user: ...]
end
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add transchange to your list of dependencies in `mix.exs`:

        def deps do
          [{:transchange, "~> 0.0.1"}]
        end

  2. Ensure transchange is started before your application:

        def application do
          [applications: [:transchange]]
        end
