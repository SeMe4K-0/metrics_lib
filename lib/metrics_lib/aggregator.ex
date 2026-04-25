defmodule MetricsLib.Aggregator do
  @moduledoc """
  Периодически читает сырые сэмплы из `MetricsLib.Storage`, вычисляет
  агрегаты (avg, p50, p95, p99), рассылает результат через PubSub и хранит
  последние 60 снапшотов в состоянии для истории дашборда.
  """

  use GenServer

  @interval_ms 5_000
  @history_size 60

  def start_link(opts) do
    interval = Keyword.get(opts, :interval_ms, @interval_ms)
    GenServer.start_link(__MODULE__, %{interval_ms: interval}, name: __MODULE__)
  end

  @doc "Возвращает самый свежий снапшот или `nil`, если агрегация ещё не запускалась."
  @spec latest() :: map() | nil
  def latest, do: GenServer.call(__MODULE__, :latest)

  @doc "Возвращает до 60 последних снапшотов (от новых к старым)."
  @spec history() :: [map()]
  def history, do: GenServer.call(__MODULE__, :history)

  @impl true
  def init(state) do
    schedule(state.interval_ms)
    {:ok, Map.put(state, :snapshots, [])}
  end

  @impl true
  def handle_info(:aggregate, state) do
    snapshot = compute_snapshot()

    Phoenix.PubSub.broadcast(
      MetricsLib.PubSub,
      "metrics:updates",
      {:snapshot, snapshot}
    )

    MetricsLib.Storage.clear()
    schedule(state.interval_ms)

    snapshots = [snapshot | Enum.take(state.snapshots, @history_size - 1)]
    {:noreply, %{state | snapshots: snapshots}}
  end

  @impl true
  def handle_call(:latest, _from, state) do
    {:reply, List.first(state.snapshots), state}
  end

  @impl true
  def handle_call(:history, _from, state) do
    {:reply, state.snapshots, state}
  end

  # --- приватные функции ---

  defp schedule(ms), do: Process.send_after(self(), :aggregate, ms)

  defp compute_snapshot do
    kv = MetricsLib.Storage.all_kv()
    samples = MetricsLib.Storage.all_samples()
    now = DateTime.utc_now()

    %{
      counters: aggregate_counters(kv),
      gauges: aggregate_gauges(kv),
      timings: aggregate_timings(samples),
      captured_at: now
    }
  end

  defp aggregate_counters(kv) do
    kv
    |> Enum.filter(fn {{type, _, _}, _} -> type == :counter end)
    |> Enum.reduce(%{}, fn {{_, name, tags}, value}, acc ->
      key = metric_key(name, tags)
      Map.update(acc, key, value, &(&1 + value))
    end)
  end

  defp aggregate_gauges(kv) do
    kv
    |> Enum.filter(fn {{type, _, _}, _} -> type == :gauge end)
    |> Enum.reduce(%{}, fn {{_, name, tags}, value}, acc ->
      key = metric_key(name, tags)
      Map.put(acc, key, value)
    end)
  end

  defp aggregate_timings(samples) do
    samples
    |> Enum.group_by(fn {{_, name, tags}, _} -> metric_key(name, tags) end)
    |> Enum.map(fn {key, entries} ->
      values = entries |> Enum.map(fn {_, v} -> v end) |> Enum.sort()
      count = length(values)
      total = Enum.sum(values)

      stats = %{
        count: count,
        sum: total,
        avg: if(count > 0, do: Float.round(total / count, 3), else: 0.0),
        min: List.first(values, 0),
        max: List.last(values, 0),
        p50: percentile(values, 0.50),
        p95: percentile(values, 0.95),
        p99: percentile(values, 0.99)
      }

      {key, stats}
    end)
    |> Map.new()
  end

  defp percentile([], _p), do: 0

  defp percentile(sorted, p) do
    idx = max(round(length(sorted) * p) - 1, 0)
    Enum.at(sorted, idx, 0)
  end

  # Формирует строковый ключ: "name" или "name{tag=val,tag2=val2}"
  defp metric_key(name, tags) when map_size(tags) == 0, do: name

  defp metric_key(name, tags) do
    tag_str =
      tags
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map_join(",", fn {k, v} -> "#{k}=#{v}" end)

    "#{name}{#{tag_str}}"
  end
end
