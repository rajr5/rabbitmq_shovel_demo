import Config

config :logger,
  level: :info

config :rmq_demo,
  rabbitmq_uri: "amqp://guest:guest@localhost:25672",
  classic_queue: "classic",
  classic_exchange: "classic_exchange",
  quorum_queue: "quorum",
  quorum_exchange: "quorum_exchange"
