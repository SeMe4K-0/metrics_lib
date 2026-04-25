# `MetricsLib.Telemetry`

Attaches handlers to `:telemetry` events emitted by Phoenix and Ecto.

Call `attach_defaults/1` once in your application's `start/2`, or pass an
explicit list of event specs to `attach/1` for fine-grained control.

## Example

    # application.ex
    def start(_type, _args) do
      MetricsLib.Telemetry.attach_defaults(repo: MyApp.Repo)
      # ...
    end

# `attach_defaults`

```elixir
@spec attach_defaults(keyword()) :: :ok | {:error, :already_exists}
```

Attach handlers for the most common Phoenix + Ecto events.

Options:
- `:repo` – your Ecto repo module (used to build the telemetry prefix).
  Defaults to guessing from the OTP app name.

# `detach`

```elixir
@spec detach() :: :ok | {:error, :not_found}
```

Detach the default handler (useful in tests).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
