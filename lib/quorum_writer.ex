defmodule RMQDemo.QuorumWriter do
  @moduledoc """
  Start with:
  {:ok, writter_pid} = GenRMQ.Publisher.start_link(RMQDemo.QuorumWriter, name: RMQDemo.QuorumWriter)

  Send messages:
  GenRMQ.Publisher.publish(RMQDemo.QuorumWriter, Jason.encode!(%{msg: "classic message"}))

  Shut down with:
  Process.exit(writter_pid, :normal)
  """
  @behaviour GenRMQ.Publisher

  def init() do
    [
      queue: Application.get_env(:rmq_demo, :quorum_queue),
      exchange: Application.get_env(:rmq_demo, :quorum_exchange),
      routing_key: "#",
      connection: Application.get_env(:rmq_demo, :rabbitmq_uri)
    ]
  end
end
