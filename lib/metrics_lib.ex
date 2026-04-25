defmodule MetricsLib do
  @moduledoc """
  Лёгкая библиотека сбора метрик для Elixir-приложений.

  ## Быстрый старт

      # mix.exs
      {:metrics_lib, "~> 0.1"}

      # Application.start/2
      MetricsLib.Telemetry.attach_defaults()

  ## Ручная инструментация

      MetricsLib.increment("user.registered")
      MetricsLib.gauge("queue.depth", length(queue))
      MetricsLib.timing("payment.latency", elapsed_ms)

  ## Дашборд

  Подключите `MetricsLib.Dashboard.Live` в роутере Phoenix:

      live "/metrics", MetricsLib.Dashboard.Live

  Дашборд обновляется каждые 5 секунд через Phoenix PubSub без перезагрузки страницы.
  """

  @doc """
  Увеличивает счётчик на `value` (по умолчанию 1).

  Счётчики накапливаются в течение окна агрегации и обнуляются
  после отправки каждого снапшота.

  ## Примеры

      MetricsLib.increment("http.requests")
      MetricsLib.increment("http.requests", 1, %{method: "GET", status: 200})
  """
  @spec increment(String.t(), number(), map()) :: :ok
  def increment(name, value \\ 1, tags \\ %{}) do
    MetricsLib.Storage.increment(name, value, tags)
  end

  @doc """
  Устанавливает значение гейджа.

  Гейджи отражают текущее состояние системы: глубину очереди,
  число активных соединений и т.п. Хранится только последнее значение.

  ## Примеры

      MetricsLib.gauge("vm.memory_mb", :erlang.memory(:total) / 1_048_576)
      MetricsLib.gauge("queue.depth", 42, %{queue: "email"})
  """
  @spec gauge(String.t(), number(), map()) :: :ok
  def gauge(name, value, tags \\ %{}) do
    MetricsLib.Storage.gauge(name, value, tags)
  end

  @doc """
  Записывает один тайминговый сэмпл в миллисекундах.

  Все сэмплы за окно агрегируются в avg/p50/p95/p99/min/max.

  ## Примеры

      start = System.monotonic_time(:millisecond)
      do_work()
      MetricsLib.timing("job.duration", System.monotonic_time(:millisecond) - start)

      MetricsLib.timing("db.query", 12.5, %{table: "users", op: "select"})
  """
  @spec timing(String.t(), number(), map()) :: :ok
  def timing(name, milliseconds, tags \\ %{}) do
    MetricsLib.Storage.timing(name, milliseconds, tags)
  end

  @doc """
  Замеряет время выполнения `fun` и записывает его как тайминг.

  Возвращает результат функции.

  ## Пример

      result = MetricsLib.measure("render.template", fn -> render_page() end)
  """
  @spec measure(String.t(), map(), (-> any())) :: any()
  def measure(name, tags \\ %{}, fun) when is_function(fun, 0) do
    start = System.monotonic_time(:millisecond)
    result = fun.()
    elapsed = System.monotonic_time(:millisecond) - start
    timing(name, elapsed, tags)
    result
  end
end
