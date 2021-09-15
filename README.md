# RabbitMQ Shovel Demo

A demo on how to migrate from a classic queue to a quorum queue using [`shovel`](https://www.rabbitmq.com/shovel.html).
The Producer/Consumer is implemented using [`GenRMQ`](https://github.com/meltwater/gen_rmq).

## Process

The process of migrating classic to quorum queues:

1. We create a quorum-type queue for all the existing classical queues
1. We migrate the reader processes to the new quorum queues
    - now there's no messages on those queues yet so readers won't do anything
1. create a `shovel` per queue to continously redirect copy messages over from the classic queue to the quorum queues
    - This'll be a bit manual but it's a one-time thing (can be automated but if we have <10 queues we should be ok)
1. We migrate the writters to the new quorum queues
1. Delete the classic queues
1. Delete the shovels

This repo contains a simplified demonstration of how that would work.

## Setup

To setup first prepare the infrastracuture:
```bash
docker-compose up
```

This starts RabbitMQ on `localhost:25672` and the RabbitMQ management UI on `localhost:35672`.

Then prepare and start the app
```bash
# start
mix deps.get
iex -S mix
```

## Running the demo

After the setup you can try out the migration process.

### 1 - Set up the Elixir app and the readers/writers

```elixir
alias GenRMQ.{Consumer, Publisher}
alias RMQDemo.{ClassicReader, ClassicWriter, QuorumReader, QuorumWriter}

# start a writter and a reader for the classic queue
{:ok, classic_writter_pid} = Publisher.start_link(ClassicWriter, name: ClassicWriter)
{:ok, classic_reader_pid} = Consumer.start_link(ClassicReader, name: ClassicReader)

# Try it out the classic queue - should be handled by ClassicReader
Publisher.publish(ClassicWriter, Jason.encode!(%{msg: "classic message"}))

# kill the classic reader (this means messages will be left in the queue)
Process.exit(classic_reader_pid, :normal)

# Try it out the classic queue again - messages won't be shown anymore
Publisher.publish(ClassicWriter, Jason.encode!(%{msg: "classic message - after killing the classic reader"}))

# start a writter and a reader for the quorum queue
{:ok, quorum_writer_pid} = Publisher.start_link(QuorumWriter, name: QuorumWriter)
{:ok, quorum_reader_pid} = Consumer.start_link(QuorumReader, name: QuorumReader)

# Try out the quorum queue - should be handled by QuorumReader
Publisher.publish(QuorumWriter, Jason.encode!(%{msg: "quorum message"}))

# now while the ClassicReader is not running generate a few new classic messages
Publisher.publish(ClassicWriter, Jason.encode!(%{msg: "classic message - new"}))
```

### 2 - Enable the Shovel

Now let's activate the shovel for message transfer from classic to the quorum queue.
In another tab connect to the RabbitMQ Docker container and start the shovel.

```sh
# Now activate the shovel to migrate the messages from the classic to the quorum queue.
# There's two ways - via UI or via the CLI, check the sections below. Here we'll show the CLI version.
# This will run the shovel continuously until deleted
docker exec -it  rqm_shovel  /bin/bash
rabbitmqctl set_parameter shovel classic-to-quorum \
'{"src-uri": "amqp://guest:guest@127.0.0.1:5672", "src-queue": "classic", "dest-uri": "amqp://guest:guest@127.0.0.1:5672", "dest-queue": "quorum", "src-delete-after": "never"}'
```

### 3 - Messages are being routes to the new queue

Now the messages are being routed, so publishing to either the classic or the quorum queue will make the

```elixir

# You'll notice the "classic message - new" being handled by the QuorumReader,
# if you try publishing messages to either the classic or the quorum queue they'll both be handled by the QuorumReader.
Publisher.publish(ClassicWriter, Jason.encode!(%{msg: "classic message - after shovel"}))
Publisher.publish(QuorumWriter, Jason.encode!(%{msg: "quorum message"}))
```


### 4 - Delete the shovel

After migrating the data, you can delete the shovel.

```sh
# After you're done you can delete the shovel
rabbitmqctl clear_parameter shovel classic-to-quorum
```

## Running shovel via UI


Go to `localhost:35672` as `guest`/`guest`, go to the "Queues" tab and open the "classic" queue, then find the "Move messages" section and for "Destination queue:" add "quorum" and click "Move messages".

This will migrate each message from the "classic" queue to the "quorum" queue and after migrating the messages the shovel will get deleted.
You can also go to the "Admin" section and then the "Shovel Management" tab.

There create a Shovel with the following info:

Name: shovel1

Source:
Protocol:AMPQ 0.9
URI: amqp://guest:guest@localhost:5672
Queue: classic

Destination:
Protocol:AMPQ 0.9
URI: amqp://guest:guest@localhost:5672
Queue: quorum

Everything else can remain blank

Then click "Add shovel", this will create the shovel and start the process.

## Running shovel via CLI

If you don't have or don't want to use the UI to handle this is should work like this:
```bash
# connect to the rabbitmq container
docker exec -it  rqm_shovel  /bin/bash

# run the shovel plugin
rabbitmqctl set_parameter shovel classic-to-quorum \
'{"src-uri": "amqp://guest:guest@localhost:5672", "src-queue": "classic", "dest-uri": "amqp://guest:guest@localhost:5672", "dest-queue": "quorum"}'
```

## Fallback for enabling shovel

If shovel isn't properly installed on docker-compose up (it should be), then try installing it manually:

```bash
# connect to the rabbitmq container
docker exec -it  rqm_shovel  /bin/bash

# enable the shovel plugin
rabbitmq-plugins enable rabbitmq_shovel rabbitmq_shovel_management
```