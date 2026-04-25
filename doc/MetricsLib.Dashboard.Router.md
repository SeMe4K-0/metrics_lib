# `MetricsLib.Dashboard.Router`

Plug router that serves the LiveView dashboard at `/metrics`.

## Embedding in an existing Phoenix app

In your `router.ex`:

    scope "/admin" do
      pipe_through [:browser]
      forward "/metrics", MetricsLib.Dashboard.Router
    end

Or mount the LiveView directly for full control:

    live "/metrics", MetricsLib.Dashboard.Live

# `browser`

# `call`

Callback invoked by Plug on every request.

# `init`

Callback required by Plug that initializes the router
for serving web requests.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
