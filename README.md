# MetricsLib

Библиотека для сбора метрик в Elixir-приложениях. Реализует три типа метрик — счётчики, гейджи и тайминги — и предоставляет LiveView-дашборд, который отображает агрегированную статистику в реальном времени без перезагрузки страницы.

Построена на стандартах экосистемы: хранение в ETS, подписка на события через `:telemetry`, обновление интерфейса через Phoenix PubSub и LiveView.

## Архитектура

Библиотека состоит из трёх независимых слоёв.

**Хранилище** (`MetricsLib.Storage`) — две публичные ETS-таблицы. Любой процесс пишет напрямую, без обращения к GenServer. Счётчики хранятся в `:set`-таблице и обновляются атомарно через `update_counter`. Тайминговые сэмплы — в `:bag`-таблице, по несколько записей на ключ.

**Агрегатор** (`MetricsLib.Aggregator`) — GenServer с таймером. Каждые 5 секунд читает все накопленные сэмплы, вычисляет avg/p50/p95/p99/min/max, рассылает снапшот подписчикам через PubSub и очищает хранилище. Хранит историю последних 60 снапшотов.

**Дашборд** (`MetricsLib.Dashboard.Live`) — LiveView-страница. Подписывается на PubSub-топик и перерисовывает только изменившиеся части DOM при каждом новом снапшоте.

```
Приложение / Phoenix / Ecto
        │
        ▼  :telemetry + прямые вызовы API
  MetricsLib.Storage      — ETS, публичная запись
        │
        ▼  каждые 5 сек
  MetricsLib.Aggregator   — avg / p50 / p95 / p99
        │
        ▼  Phoenix.PubSub
  MetricsLib.Dashboard.Live — обновление в браузере через WebSocket
```

## Типы метрик

**Счётчики** — монотонно возрастающие целые числа. Накапливаются в течение окна агрегации, сбрасываются после каждого снапшота.

```elixir
MetricsLib.increment("orders.created")
MetricsLib.increment("http.errors", 1, %{status: 500})
```

**Гейджи** — текущее состояние системы. Хранится только последнее записанное значение.

```elixir
MetricsLib.gauge("queue.depth", length(pending))
MetricsLib.gauge("vm.memory_mb", :erlang.memory(:total) / 1_048_576)
```

**Тайминги** — время выполнения операций в миллисекундах. Все сэмплы за окно агрегируются в статистику.

```elixir
MetricsLib.timing("db.query", elapsed_ms, %{table: "orders"})

result = MetricsLib.measure("payment.charge", fn ->
  PaymentGateway.charge(card, amount)
end)
```

## Интеграция с Telemetry

Phoenix и Ecto автоматически отправляют события через `:telemetry`. Достаточно одного вызова при старте приложения — и все HTTP-запросы и SQL-запросы начнут попадать в метрики.

```elixir
# lib/my_app/application.ex
def start(_type, _args) do
  MetricsLib.Telemetry.attach_defaults(repo: MyApp.Repo)
  ...
end
```

Захватываются события `phoenix.router_dispatch.stop` и `<app>.repo.query`.

## Дашборд

```elixir
# lib/my_app_web/router.ex
scope "/internal" do
  pipe_through :browser
  live "/metrics", MetricsLib.Dashboard.Live
end
```

Дашборд отображает три таблицы — тайминги (со столбцами avg/p50/p95/p99/max), счётчики и гейджи. Данные приходят через WebSocket каждые 5 секунд; перезагрузка страницы не требуется.

## Установка

```elixir
# mix.exs
def deps do
  [
    {:metrics_lib, "~> 0.1"}
  ]
end
```

## Конфигурация

Интервал агрегации задаётся через child spec:

```elixir
{MetricsLib.Aggregator, interval_ms: 10_000}
```

## Документация

```bash
mix docs
open doc/index.html
```