defmodule MetricsLibTest do
  use ExUnit.Case, async: false

  setup do
    MetricsLib.Storage.clear()
    :ok
  end

  describe "increment/3" do
    test "добавляет строку счётчика в ETS" do
      MetricsLib.increment("hits")
      rows = MetricsLib.Storage.all_kv()
      assert Enum.any?(rows, fn {{type, name, _}, _} -> type == :counter and name == "hits" end)
    end

    test "накапливает значения при нескольких вызовах" do
      MetricsLib.increment("hits", 3)
      MetricsLib.increment("hits", 2)
      [{_key, value}] =
        MetricsLib.Storage.all_kv()
        |> Enum.filter(fn {{_, name, _}, _} -> name == "hits" end)

      assert value == 5
    end
  end

  describe "gauge/3" do
    test "сохраняет значение гейджа" do
      MetricsLib.gauge("queue.depth", 42)
      [{_key, value}] =
        MetricsLib.Storage.all_kv()
        |> Enum.filter(fn {{type, name, _}, _} -> type == :gauge and name == "queue.depth" end)

      assert value == 42
    end
  end

  describe "timing/3" do
    test "добавляет тайминговые сэмплы" do
      MetricsLib.timing("response_time", 10)
      MetricsLib.timing("response_time", 20)
      MetricsLib.timing("response_time", 30)

      samples =
        MetricsLib.Storage.all_samples()
        |> Enum.filter(fn {{_, name, _}, _} -> name == "response_time" end)

      assert length(samples) == 3
    end
  end

  describe "measure/3" do
    test "замеряет время и возвращает результат функции" do
      result = MetricsLib.measure("work", fn ->
        Process.sleep(1)
        :done
      end)

      assert result == :done

      samples =
        MetricsLib.Storage.all_samples()
        |> Enum.filter(fn {{_, name, _}, _} -> name == "work" end)

      assert length(samples) == 1
      [{_key, ms}] = samples
      assert ms >= 0
    end
  end

  describe "теги" do
    test "метрики с разными тегами хранятся отдельно" do
      MetricsLib.increment("req", 1, %{status: 200})
      MetricsLib.increment("req", 1, %{status: 500})

      rows =
        MetricsLib.Storage.all_kv()
        |> Enum.filter(fn {{_, name, _}, _} -> name == "req" end)

      assert length(rows) == 2
    end
  end
end
