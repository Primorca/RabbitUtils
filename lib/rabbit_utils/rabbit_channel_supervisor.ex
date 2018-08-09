defmodule RabbitUtils.RabbitChannelSupervisor do
  use DynamicSupervisor
  require Logger

  def start_link do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(name, conn, channel_type) do
    Logger.info("In start child of channel sup")
    spec = %{id: channel_type, start: {channel_type, :start_link, [name, conn]}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

end
