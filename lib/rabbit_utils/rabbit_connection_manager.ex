defmodule RabbitUtils.RabbitConnectionManager do
  use GenServer
  use AMQP
  require Logger

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  def set_address(address) do
    GenServer.call(__MODULE__, {:set_address, address})
  end

  def close_connection do
    GenServer.call(__MODULE__, :close)
  end

  def get_connection do
    GenServer.call(__MODULE__, :connect, :infinity)
  end

  def init(state) do
    {:ok, %{conn: nil, address: nil, monitor: nil}}
  end

  defp rabbitmq_connect(connect_address) do
    case Connection.open(connect_address) do
      {:ok, conn} ->
        # Get notifications when the connection goes down
        ref = Process.monitor(conn.pid)
        # Everything else remains the same
        {:ok, conn, ref}
      {:error, _} ->
        # Reconnection loop
        :timer.sleep(10000)
        rabbitmq_connect(connect_address)
    end
  end

  def handle_call({:set_address, address}, _from, state) do
    {:reply, state, %{state | address: address}}
  end

  def handle_call(:connect, _from, %{:conn => conn, :address => address} = state) do
    if (conn == nil && address == nil) do
      {:reply, nil, state}
    else
      if (conn == nil) do
        {:ok, new_conn, ref} = rabbitmq_connect(address)
        {:reply, new_conn, %{state | conn: new_conn, monitor: ref}}
      else
        {:reply, conn, state}
      end
    end
  end

  def handle_info({:DOWN, _, :process, _pid, _reason}, %{:address => address} = state) do
    Logger.info("reconnecting")
    if (address == nil) do
      {:noreply, state}
    else
      {:ok, conn, ref} = rabbitmq_connect(address)
      {:noreply, %{state | conn: conn, monitor: ref}}
    end
  end

  def handle_call(:close, _from, %{:conn => conn, :monitor => monitor} = state) do
    if (monitor != nil) do
      Process.demonitor(monitor)
    end
    if (conn != nil) do
      Connection.close(conn)
    end
    {:reply, :ok, %{state | conn: nil, address: nil, monitor: nil}}
  end
end
