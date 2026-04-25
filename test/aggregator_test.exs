defmodule MetricsLib.AggregatorTest do
  use ExUnit.Case, async: false

  setup do
    MetricsLib.Storage.clear()
    :ok
  end

  describe "перцентили тайминга" do
    test "корректно вычисляет avg, p50, p95, p99 для 100 значений" do
      for i <- 1..100 do
        MetricsLib.timing("latency", i)
      end

      Phoenix.PubSub.subscribe(MetricsLib.PubSub, "metrics:updates")
      send(MetricsLib.Aggregator, :aggregate)

      assert_receive {:snapshot, snapshot}, 1_000

      stats = snapshot.timings["latency"]
      assert stats.count == 100
      assert stats.p50 == 50
      assert stats.p95 == 95
      assert stats.p99 == 99
      assert stats.min == 1
      assert stats.max == 100
      assert_in_delta stats.avg, 50.5, 0.1
    end
  end

  test "счётчики суммируются по всем строкам ETS" do
    MetricsLib.increment("errors", 3)
    MetricsLib.increment("errors", 2)

    Phoenix.PubSub.subscribe(MetricsLib.PubSub, "metrics:updates")
    send(MetricsLib.Aggregator, :aggregate)

    assert_receive {:snapshot, snapshot}, 1_000
    assert snapshot.counters["errors"] == 5
  end
end
