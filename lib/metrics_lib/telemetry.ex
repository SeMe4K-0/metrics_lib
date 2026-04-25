defmodule MetricsLib.Telemetry do
  @moduledoc """
  Подключение к стандартным `:telemetry`-событиям Phoenix и Ecto.

  Вызовите `attach_defaults/1` один раз в `Application.start/2` вашего
  приложения — и метрики HTTP-запросов и SQL-запросов начнут поступать
  автоматически.

  ## Пример

      # lib/my_app/application.ex
      def start(_type, _args) do
        MetricsLib.Telemetry.attach_defaults(repo: MyApp.Repo)
        # ...
      end
  """

  require Logger

  @handler_id "metrics-lib-default"

  @doc """
  Подписывается на стандартные события Phoenix и Ecto.

  Опции:
  - `:repo` — модуль вашего Ecto.Repo (используется для построения
    telemetry-префикса). По умолчанию выводится из имени OTP-приложения.
  """
  @spec attach_defaults(keyword()) :: :ok | {:error, :already_exists}
  def attach_defaults(opts \\ []) do
    repo_prefix =
      case Keyword.get(opts, :repo) do
        nil ->
          [Mix.Project.config()[:app], :repo]

        repo ->
          repo
          |> Module.split()
          |> Enum.map(&String.downcase/1)
          |> Enum.map(&String.to_atom/1)
      end

    events = [
      [:phoenix, :router_dispatch, :stop],
      [:phoenix, :endpoint, :stop],
      repo_prefix ++ [:query]
    ]

    :telemetry.attach_many(@handler_id, events, &__MODULE__.handle_event/4, nil)
  end

  @doc "Отключает обработчик событий (полезно в тестах)."
  @spec detach() :: :ok | {:error, :not_found}
  def detach, do: :telemetry.detach(@handler_id)

  @doc false
  def handle_event([:phoenix, :router_dispatch, :stop], measurements, metadata, _cfg) do
    ms = native_to_ms(measurements[:duration])

    MetricsLib.timing("phoenix.router_dispatch", ms, %{
      route: to_string(Map.get(metadata, :route, "unknown")),
      method: get_in(metadata, [:conn, Access.key(:method)]) || "UNKNOWN",
      status: get_in(metadata, [:conn, Access.key(:status)]) || 0
    })
  end

  def handle_event([:phoenix, :endpoint, :stop], measurements, metadata, _cfg) do
    ms = native_to_ms(measurements[:duration])

    MetricsLib.timing("phoenix.endpoint", ms, %{
      status: get_in(metadata, [:conn, Access.key(:status)]) || 0
    })
  end

  def handle_event([_app, :repo, :query], measurements, metadata, _cfg) do
    ms = System.convert_time_unit(measurements[:total_time] || 0, :native, :millisecond)

    MetricsLib.timing("ecto.query", ms, %{
      source: to_string(metadata[:source] || "unknown")
    })
  end

  def handle_event(event, _measurements, _metadata, _cfg) do
    Logger.debug("[MetricsLib] необработанное telemetry-событие: #{inspect(event)}")
  end

  defp native_to_ms(nil), do: 0
  defp native_to_ms(native), do: System.convert_time_unit(native, :native, :millisecond)
end
