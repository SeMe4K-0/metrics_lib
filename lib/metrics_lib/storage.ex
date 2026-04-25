defmodule MetricsLib.Storage do
  @moduledoc """
  Хранилище сырых метрик на основе ETS.

  Используются две таблицы:

  - `:metrics_kv`      — тип `:set`, хранит счётчики (атомарный `update_counter`)
                         и значения гейджей.
  - `:metrics_samples` — тип `:bag`, хранит тайминговые сэмплы
                         (несколько строк на один ключ).

  Обе таблицы `:public`, поэтому любой процесс пишет напрямую без
  прохождения через GenServer-бутылочное горлышко.
  `read_concurrency: true` оптимизирует параллельные чтения из агрегатора.
  """

  use GenServer

  @kv_table :metrics_kv
  @sample_table :metrics_samples

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl true
  def init(_) do
    :ets.new(@kv_table, [:named_table, :public, :set, read_concurrency: true, write_concurrency: true])
    :ets.new(@sample_table, [:named_table, :public, :bag, read_concurrency: true])
    {:ok, %{}}
  end

  @doc "Атомарно увеличивает счётчик на `value`."
  @spec increment(String.t(), number(), map()) :: :ok
  def increment(name, value, tags) do
    key = {:counter, name, tags}
    :ets.update_counter(@kv_table, key, {2, value}, {key, 0})
    :ok
  end

  @doc "Устанавливает значение гейджа (перезаписывает предыдущее)."
  @spec gauge(String.t(), number(), map()) :: :ok
  def gauge(name, value, tags) do
    :ets.insert(@kv_table, {{:gauge, name, tags}, value})
    :ok
  end

  @doc "Добавляет один тайминговый сэмпл."
  @spec timing(String.t(), number(), map()) :: :ok
  def timing(name, milliseconds, tags) do
    :ets.insert(@sample_table, {{:timing, name, tags}, milliseconds})
    :ok
  end

  @doc "Возвращает все строки счётчиков и гейджей."
  @spec all_kv() :: list()
  def all_kv, do: :ets.tab2list(@kv_table)

  @doc "Возвращает все тайминговые сэмплы."
  @spec all_samples() :: list()
  def all_samples, do: :ets.tab2list(@sample_table)

  @doc "Очищает обе таблицы (используется между окнами агрегации и в тестах)."
  @spec clear() :: :ok
  def clear do
    :ets.delete_all_objects(@kv_table)
    :ets.delete_all_objects(@sample_table)
    :ok
  end
end
