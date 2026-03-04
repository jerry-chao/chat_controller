# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :chat_controller,
  ecto_repos: [ChatController.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :chat_controller, ChatControllerWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ChatControllerWeb.ErrorHTML, json: ChatControllerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ChatController.PubSub,
  live_view: [signing_salt: "wx4utl4H"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :chat_controller, ChatController.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  chat_controller: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  chat_controller: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Jido AI configuration
config :jido_ai,
  model_aliases: %{
    fast: "openai:gpt-3.5-turbo",
    capable: "openai:gpt-4",
    bigmodel_glm4: :bigmodel_glm4
  }

config :req_llm,
  openai_api_key: System.get_env("OPENAI_API_KEY"),
  custom_providers: [ChatController.AI.BigModel]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
