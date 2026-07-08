import Config

# Configure your database
config :popcorn, Popcorn.Repo,
  username: "postgres",
  password: "postgres",
  database: "popcorn_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# In test we don't send emails.
config :popcorn, Popcorn.Emails.Mailer, adapter: Swoosh.Adapters.Test

# Print only errors during test
config :logger, level: :error

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :popcorn, PopcornWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4001],
  secret_key_base: "ssecretkeybasesecretkeybasesecretkeybasesecretkeybaseecretkeybase",
  server: false

config :popcorn, PopcornAdmin.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4003],
  secret_key_base: "ssecretkeybasesecretkeybasesecretkeybasesecretkeybaseecretkeybase",
  server: false

config :popcorn, PopcornWeb.Plug.AdminGate, enabled: true

config :popcorn, Popcorn.Accounts,
  secret: "ssecretkeybasesecretkeybasesecretkeybasesecretkeybaseecretkeybase"

config :popcorn, Popcorn.FileStore.Local, path: "uploads/test/"

config :popcorn, Popcorn.FileCache, path: "/tmp/popcorn"

config :popcorn, Oban, testing: :manual

config :popcorn, Popcorn.Telemetry, enabled: false

config :os_mon,
  start_cpu_sup: false,
  start_memsup: false,
  start_disksup: false

config :stream_data, max_runs: 1000

config :phoenix_test, :endpoint, PopcornWeb.Endpoint
