defmodule MetricsLib.Dashboard.Router do
  @moduledoc """
  Plug-роутер, раздающий LiveView-дашборд по пути `/`.

  ## Встраивание в Phoenix-приложение

  Вариант 1 — перенаправить через `forward`:

      scope "/admin" do
        pipe_through [:browser]
        forward "/metrics", MetricsLib.Dashboard.Router
      end

  Вариант 2 — смонтировать LiveView напрямую (рекомендуется):

      live "/metrics", MetricsLib.Dashboard.Live
  """

  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/" do
    pipe_through :browser
    live "/", MetricsLib.Dashboard.Live, :index, as: :metrics_dashboard
  end
end
