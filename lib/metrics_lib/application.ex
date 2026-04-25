defmodule MetricsLib.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # PubSub нужен агрегатору для рассылки снапшотов дашборду
      {Phoenix.PubSub, name: MetricsLib.PubSub},
      # ETS-хранилище сырых метрик
      MetricsLib.Storage,
      # GenServer-агрегатор: вычисляет статистику каждые 5 сек
      {MetricsLib.Aggregator, []}
    ]

    opts = [strategy: :one_for_one, name: MetricsLib.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
