defmodule RabbitUtils.RabbitChannel do
  use AMQP

  defmacro __using__(_) do
    quote do
      require Logger
      use GenServer

      @impl true
      def init(conn) do
        {:ok, chan} = Channel.open(conn)
        {:ok, %{channel: chan}}
      end
      defoverridable [init: 1]

      def via_tuple(name) do
        {:via, :gproc, {:n, :l, {__MODULE__, name}}}
      end

      def start_link(name, conn) do
        GenServer.start_link(__MODULE__, conn, name: __MODULE__.via_tuple(name))
      end

      def get_state(name) do
        GenServer.call(__MODULE__.via_tuple(name), :get_state)
      end

      def declare_queue(name, queue_name) do
        GenServer.call(__MODULE__.via_tuple(name), {:declare_queue, queue_name})
      end

      def declare_exchange(name, exchange_name) do
        GenServer.call(__MODULE__.via_tuple(name), {:declare_exchange, exchange_name})
      end

      def bind_queue_to_exchange(name, queue_name, exchange_name) do
        GenServer.call(__MODULE__.via_tuple(name), {:bind_queue_to_exchange, queue_name, exchange_name})
      end


      def publish_message(name, exchange_name, queue_name, payload) do
        GenServer.call(__MODULE__.via_tuple(name), {:basic_publish, exchange_name, queue_name, payload})
      end

      @impl true
      def handle_call(:get_state, _from, state) do
        {:reply, state, state}
      end

      @impl true
      def handle_call({:declare_queue, queue_name}, _from, %{:channel => channel} = state) do
        Queue.declare(channel, queue_name)
        {:reply, :ok, state}
      end


      @impl true
      def handle_call({:declare_exchange, exchange_name}, _from, %{:channel => channel} = state) do
        Exchange.declare(channel, exchange_name)
        {:reply, :ok, state}
      end

      @impl true
      def handle_call({:bind_queue_to_exchange, queue_name, exchange_name}, _from, %{:channel => channel} = state) do
        Queue.bind(channel, queue_name, exchange_name)
        {:reply, :ok, state}
      end


      @impl true
      def handle_call({:basic_publish, exchange_name, queue_name, payload}, _from, %{:channel => channel} = state) do
        Basic.publish(channel, exchange_name, queue_name, payload)
        {:reply, :ok, state}
      end

    end
  end

end
