defmodule RMQDemo.QuorumReader do
  @moduledoc """
  Start with:
  {:ok, quorum_reader_pid} = GenRMQ.Consumer.start_link(RMQDemo.QuorumReader, name: RMQDemo.QuorumReader)

  End with:
  Process.exit(quorum_reader_pid, :normal)
  """
  @behaviour GenRMQ.Consumer
  require Logger

  @impl GenRMQ.Consumer
  def init() do
    [
      queue: Application.get_env(:rmq_demo, :quorum_queue),
      exchange: Application.get_env(:rmq_demo, :quorum_exchange),
      routing_key: "#",
      prefetch_count: "10",
      connection: Application.get_env(:rmq_demo, :rabbitmq_uri)
    ]
  end

  @impl GenRMQ.Consumer
  def consumer_tag() do
    name()
  end

  @impl GenRMQ.Consumer
  def handle_message(message) do
    Logger.info("#{name()} received message: #{inspect(Jason.decode!(message.payload))}")

    GenRMQ.Consumer.ack(message)
  end

  @impl GenRMQ.Consumer
  def handle_error(message, _reason) do
    Logger.error("#{name()} queue error message: #{inspect(message)}")

    GenRMQ.Consumer.reject(message, true)
  end

  defp name do
    __MODULE__ |> Atom.to_string() |> String.split(".") |> List.last()
  end
end
