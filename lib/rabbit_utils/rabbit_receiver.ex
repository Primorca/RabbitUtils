defmodule RabbitUtils.RabbitReceiver do
  @moduledoc false

  @callback receive_message(message :: any, state :: any) :: new_state :: any

  defmacro __using__(_) do
    quote do
      use GenServer

      @behaviour RabbitUtils.RabbitReceiver

      @impl true
      def handle_info({:rabbit_message, message}, state) do
        {:noreply, receive_message(message, state)}
      end

    end
  end

end
