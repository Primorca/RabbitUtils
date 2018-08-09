defmodule RabbitUtils.RabbitConsumer do
  use AMQP

  @callback handle_consume(chan :: any, tag :: any, redelivered :: any, payload :: any, state :: any) :: {:ok, should_ack :: boolean}
  @callback handle_conversion(payload :: any, state :: any) :: {:ok, new_payload :: any}
  @moduledoc false

  defmacro __using__(_) do
    quote do
      require Logger
      use RabbitUtils.RabbitChannel

      @behaviour RabbitUtils.RabbitConsumer

      def start_consume(name, queue_name) do
        GenServer.call(__MODULE__.via_tuple(name), {:basic_consume, queue_name})
      end

      @impl true
      def handle_call({:basic_consume, queue_name}, _from, %{:channel => channel} = state) do
        {:ok, consumer_tag} = Basic.consume(channel, queue_name)
        {:reply, consumer_tag, state}

      end

      @impl true
      def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}},
            %{:channel => channel} = state) do
        {:ok, converted} = handle_conversion(payload, state)
        spawn fn ->
          case handle_consume(channel, tag, redelivered, converted, state) do
            {:ok, true} -> Basic.ack(channel, tag)
            {:ok, false} -> Basic.reject(channel, tag)
          end
        end
        {:noreply, state}
      end

      # Confirmation sent by the broker after registering this process as a consumer
      @impl true
      def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, %{:channel => channel} = state) do
        {:noreply, state}
      end

      # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
      @impl true
      def handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, %{:channel => channel} = state) do
        {:stop, :normal, state}
      end

      # Confirmation sent by the broker to the consumer process after a Basic.cancel
      @impl true
      def handle_info({:basic_cancel_ok, %{consumer_tag: consumer_tag}}, %{:channel => channel} = state) do
        {:noreply, state}
      end
    end
  end


end
