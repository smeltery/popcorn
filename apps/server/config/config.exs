# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :popcorn, version: System.get_env("VERSION")

config :popcorn, :session_opts,
  store: :cookie,
  key: "_popcorn_key",
  signing_salt: "qJL+3s0T",
  same_site: "Lax"

config :popcorn,
  ecto_repos: [Popcorn.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the public endpoint
config :popcorn, PopcornWeb.Endpoint,
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  url: [host: "localhost"],
  render_errors: [
    formats: [
      html: PopcornWeb.ErrorHTML,
      json: PopcornWeb.ErrorJSON,
      txt: PopcornWeb.ErrorTEXT,
      svg: PopcornWeb.ErrorTEXT,
      xml: PopcornWeb.ErrorTEXT
    ],
    layout: false
  ],
  live_view: [signing_salt: "F3BMP7k9SZ-Y2SMJ"],
  pubsub_server: Popcorn.PubSub

# Configures the admin endpoint
config :popcorn, PopcornAdmin.Endpoint,
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: PopcornAdmin.ErrorHTML],
    layout: false
  ],
  live_view: [signing_salt: "F3BMP7k9SZ-Y2SMJ"],
  pubsub_server: Popcorn.PubSub

# Serving the admin panel at /admin on the main endpoint is opt-in
config :popcorn, PopcornWeb.Plug.AdminGate, enabled: false

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :popcorn, :logger, [
  {:handler, :sentry, Sentry.LoggerHandler,
   %{
     config: %{
       metadata: [:file, :line],
       rate_limiting: [max_events: 10, interval: _1_second = 1_000]
     }
   }}
]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :phoenix_template, :format_encoders,
  pop: Jason,
  svg: Phoenix.HTML.Engine,
  xml: Phoenix.HTML.Engine

config :mime, :types, %{
  "application/x-popcast" => ["pop"]
}

config :popcorn, Popcorn.Emails.Mailer, adapter: Swoosh.Adapters.Local

config :sentry,
  environment_name: config_env(),
  client: Sentry.HackneyClient,
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()],
  tags: %{env: config_env()},
  in_app_module_allow_list: [Popcorn],
  before_send: {Popcorn.SentryFilter, :before_send}

config :popcorn, Popcorn.FileStore, adapter: Popcorn.FileStore.Local
config :popcorn, Popcorn.FileStore.Local, path: "uploads/"

config :popcorn, Popcorn.FileCache,
  path: "cache/",
  buckets: [
    pop: 60 * 60 * 24 * 30,
    pop_zst: 60 * 60 * 24 * 30,
    pop_gz: 60 * 60 * 24 * 30,
    txt: 60 * 60 * 24 * 30,
    txt_zst: 60 * 60 * 24 * 30,
    txt_gz: 60 * 60 * 24 * 30,
    svg: 60 * 60 * 24 * 30,
    svg_zst: 60 * 60 * 24 * 30,
    svg_gz: 60 * 60 * 24 * 30,
    png: 60 * 60 * 24 * 30
  ]

config :popcorn, PopcornWeb.PngGenerator, font_family: "monospace"

config :popcorn, PopcornWeb.DefaultAvatar, adapter: PopcornWeb.DefaultAvatar.Identicon

config :popcorn, Oban,
  repo: Popcorn.Repo,
  queues: [default: 5, emails: 5, maintenance: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 3600},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 * * * *", Popcorn.Workers.DeleteUnclaimedRecordings},
       {"* * * * *", Popcorn.Workers.MarkOfflineStreams},
       {"* * * * *", Popcorn.Workers.RescheduleStreams},
       {"0 3 * * *", Popcorn.Workers.RecomputePopularityScores},
       {"*/5 * * * *", Popcorn.Workers.RecomputeDirtyPopularityScores}
     ]},
    Oban.Plugins.Lifeline,
    Oban.Plugins.Reindexer
  ]

config :tzdata, :autoupdate, :disabled

librejs_license =
  "/* @license magnet:?xt=urn:btih:8e4f440f4c65981c5bf93c76d35135ba5064d8b7&dn=apache-2.0.txt Apache-2.0 */"

librejs_license_end = "/* @license-end */"

config :esbuild,
  version: "0.21.5",
  default: [
    args:
      ~w(js/app.js js/iframe.js --bundle --target=es2022 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*) ++
        ["--banner:js=#{librejs_license}", "--footer:js=#{librejs_license_end}"],
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ],
  admin: [
    args:
      ~w(js/admin.js css/admin.css --bundle --target=es2022 --outdir=../priv/static/assets --entry-names=[name] --external:/fonts/* --external:/images/*) ++
        ["--banner:js=#{librejs_license}", "--footer:js=#{librejs_license_end}"],
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.4.3",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ],
  iframe: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/iframe.css
      --output=../priv/static/assets/iframe.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
