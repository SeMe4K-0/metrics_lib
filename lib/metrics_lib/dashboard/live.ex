defmodule MetricsLib.Dashboard.Live do
  @moduledoc """
  LiveView-дашборд MetricsLib с обновлением в реальном времени.

  Подключите в роутере Phoenix:

      live "/metrics", MetricsLib.Dashboard.Live
  """

  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MetricsLib.PubSub, "metrics:updates")
    end

    snapshot = MetricsLib.Aggregator.latest()
    {:ok, assign(socket, snapshot: snapshot, history: MetricsLib.Aggregator.history())}
  end

  @impl true
  def handle_info({:snapshot, snapshot}, socket) do
    {:noreply,
     assign(socket,
       snapshot: snapshot,
       history: [snapshot | Enum.take(socket.assigns.history, 59)]
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="metrics-dashboard" style="font-family: monospace; padding: 1rem;">
      <h1 style="font-size: 1.5rem; margin-bottom: 1rem;">MetricsLib — Дашборд</h1>

      <%= if @snapshot do %>
        <p style="color: #888; margin-bottom: 1.5rem;">
          Последнее обновление: <%= Calendar.strftime(@snapshot.captured_at, "%H:%M:%S UTC") %>
        </p>

        <%= if map_size(@snapshot.timings) > 0 do %>
          <section>
            <h2 style="font-size: 1.1rem; margin-bottom: 0.5rem;">Тайминги (мс)</h2>
            <table style="border-collapse: collapse; width: 100%;">
              <thead>
                <tr style="text-align: left; border-bottom: 1px solid #ccc;">
                  <th style="padding: 0.4rem 1rem 0.4rem 0;">Метрика</th>
                  <th style="padding: 0.4rem 0.5rem;">кол-во</th>
                  <th style="padding: 0.4rem 0.5rem;">avg</th>
                  <th style="padding: 0.4rem 0.5rem;">p50</th>
                  <th style="padding: 0.4rem 0.5rem;">p95</th>
                  <th style="padding: 0.4rem 0.5rem;">p99</th>
                  <th style="padding: 0.4rem 0.5rem;">max</th>
                </tr>
              </thead>
              <tbody>
                <%= for {name, s} <- Enum.sort(@snapshot.timings) do %>
                  <tr style="border-bottom: 1px solid #eee;">
                    <td style="padding: 0.4rem 1rem 0.4rem 0;"><%= name %></td>
                    <td style="padding: 0.4rem 0.5rem;"><%= s.count %></td>
                    <td style="padding: 0.4rem 0.5rem;"><%= s.avg %></td>
                    <td style="padding: 0.4rem 0.5rem;"><%= s.p50 %></td>
                    <td style="padding: 0.4rem 0.5rem;"><%= s.p95 %></td>
                    <td style="padding: 0.4rem 0.5rem;"><%= s.p99 %></td>
                    <td style="padding: 0.4rem 0.5rem;"><%= s.max %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </section>
        <% end %>

        <%= if map_size(@snapshot.counters) > 0 do %>
          <section style="margin-top: 1.5rem;">
            <h2 style="font-size: 1.1rem; margin-bottom: 0.5rem;">Счётчики</h2>
            <table style="border-collapse: collapse; width: 100%;">
              <thead>
                <tr style="text-align: left; border-bottom: 1px solid #ccc;">
                  <th style="padding: 0.4rem 1rem 0.4rem 0;">Метрика</th>
                  <th style="padding: 0.4rem 0.5rem;">значение</th>
                </tr>
              </thead>
              <tbody>
                <%= for {name, value} <- Enum.sort(@snapshot.counters) do %>
                  <tr style="border-bottom: 1px solid #eee;">
                    <td style="padding: 0.4rem 1rem 0.4rem 0;"><%= name %></td>
                    <td style="padding: 0.4rem 0.5rem;"><%= value %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </section>
        <% end %>

        <%= if map_size(@snapshot.gauges) > 0 do %>
          <section style="margin-top: 1.5rem;">
            <h2 style="font-size: 1.1rem; margin-bottom: 0.5rem;">Гейджи</h2>
            <table style="border-collapse: collapse; width: 100%;">
              <thead>
                <tr style="text-align: left; border-bottom: 1px solid #ccc;">
                  <th style="padding: 0.4rem 1rem 0.4rem 0;">Метрика</th>
                  <th style="padding: 0.4rem 0.5rem;">значение</th>
                </tr>
              </thead>
              <tbody>
                <%= for {name, value} <- Enum.sort(@snapshot.gauges) do %>
                  <tr style="border-bottom: 1px solid #eee;">
                    <td style="padding: 0.4rem 1rem 0.4rem 0;"><%= name %></td>
                    <td style="padding: 0.4rem 0.5rem;"><%= value %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </section>
        <% end %>

      <% else %>
        <p style="color: #888;">Ожидание первого окна агрегации (5 сек)...</p>
      <% end %>
    </div>
    """
  end
end
