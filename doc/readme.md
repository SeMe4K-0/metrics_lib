# MetricsLib

Lightweight metrics collection for Elixir applications — counters, gauges, timings — with a real-time LiveView dashboard powered by Phoenix PubSub and ETS.

[![Hex.pm](https://img.shields.io/hexpm/v/metrics_lib.svg)](https://hex.pm/packages/metrics_lib)

## Features

- **Three metric types** — counters, gauges, timings (with auto-computed avg/p50/p95/p99)
- **Zero-bottleneck writes** — ETS public table; any process writes directly, no GenServer round-trip
- **Telemetry integration** — one call to capture Phoenix request times, Ecto query times, and any custom `:telemetry` events
- **Real-time dashboard** — Phoenix LiveView page that auto-updates every 5 s without a page reload
- **Hex-friendly** — documented with ExDoc, typed with `@spec`, easy to embed in any Phoenix app

## Installation

```elixir
# mix.exs
def deps do
  [
    {:metrics_lib, "~> 0.1"}
  ]
end
```

## Quick start

### 1. Attach Telemetry handlers (optional but recommended)

```elixir
# lib/my_app/application.ex
def start(_type, _args) do
  MetricsLib.Telemetry.attach_defaults(repo: MyApp.Repo)
  # ...
end
```

This captures `phoenix.router_dispatch` and `ecto.query` timings automatically.

### 2. Manual instrumentation

```elixir
# Counter — increments an integer
MetricsLib.increment("user.registered")
MetricsLib.increment("http.errors", 1, %{status: 500})

# Gauge — set a current value
MetricsLib.gauge("queue.depth", Enum.count(pending_jobs))

# Timing — record elapsed milliseconds
MetricsLib.timing("payment.charge", elapsed_ms, %{provider: "stripe"})

# Measure — wraps a function, records its wall time
result = MetricsLib.measure("heavy_computation", fn -> compute() end)
```

### 3. Mount the dashboard

```elixir
# lib/my_app_web/router.ex
scope "/" do
  pipe_through :browser
  live "/metrics", MetricsLib.Dashboard.Live
end
```

Navigate to `/metrics` — you'll see live-updating tables of all your metrics, refreshed every 5 seconds.

## How it works

```
Your code / Phoenix / Ecto
        │
        ▼  :telemetry events + direct calls
  MetricsLib.Storage  ◄── ETS :bag table (public, fast writes)
        │
        ▼  every 5 s
  MetricsLib.Aggregator  ──► computes avg/p50/p95/p99
        │
        ▼  Phoenix.PubSub broadcast
  MetricsLib.Dashboard.Live  ──► pushes diff to browser via WebSocket
```

## Configuration

The aggregation interval can be changed at startup via application config:

```elixir
# config/config.exs  (not yet wired — pass as child spec option)
{MetricsLib.Aggregator, interval_ms: 10_000}
```

## Documentation

Generate locally:

```bash
mix docs
open doc/index.html
```

## License

MIT
