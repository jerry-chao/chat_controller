defmodule ChatController.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ChatControllerWeb.Telemetry,
      ChatController.Repo,
      {DNSCluster, query: Application.get_env(:chat_controller, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ChatController.PubSub},

      # Start a worker by calling: ChatController.Worker.start_link(arg)
      # {ChatController.Worker, arg},
      # Start to serve requests, typically the last entry
      ChatControllerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChatController.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ChatControllerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
