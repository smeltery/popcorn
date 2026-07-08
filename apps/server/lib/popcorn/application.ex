defmodule Popcorn.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :ok = Oban.Telemetry.attach_default_logger()
    :ok = Popcorn.ObanErrorReporter.configure()
    Logger.add_handlers(:popcorn)

    topologies = Application.get_env(:libcluster, :topologies, [])

    # List all child processes to be supervised
    children = [
      # Start task supervisor
      {Task.Supervisor, name: Popcorn.TaskSupervisor},
      # Start cluster supervisor
      {Cluster.Supervisor, [topologies, [name: Popcorn.ClusterSupervisor]]},
      # Start the PubSub system
      {Phoenix.PubSub, [name: Popcorn.PubSub, adapter: Phoenix.PubSub.PG2]},
      # Start stream viewer tracker
      {Popcorn.Streaming.ViewerTracker, [pubsub_server: Popcorn.PubSub]},
      # Start telemetry reporters
      Popcorn.Telemetry,
      # Start the Ecto repository
      Popcorn.Repo,
      # Start file cache
      {Popcorn.FileCache, file_cache_opts()},
      # Start PNG generator
      PopcornWeb.PngGenerator,
      # Start Oban
      {Oban, oban_config()},
      # Start distributed registry
      {Horde.Registry, [name: Popcorn.Streaming.StreamRegistry, keys: :unique, members: :auto]},
      Popcorn.Streaming.StreamSupervisor,
      # Start rate limiter
      {PlugAttack.Storage.Ets, name: PopcornWeb.PlugAttack.Storage, clean_period: 60_000},
      # Start the public endpoint
      PopcornWeb.Endpoint,
      # Start the admin endpoint
      PopcornAdmin.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Popcorn.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PopcornWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp oban_config do
    Application.fetch_env!(:popcorn, Oban)
  end

  defp file_cache_opts do
    [name: Popcorn.FileCache] ++ Application.fetch_env!(:popcorn, Popcorn.FileCache)
  end
end
