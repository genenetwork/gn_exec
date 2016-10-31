defmodule GnExec.Queue do
  use GenServer

  # Client

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def push(item) do
    GenServer.cast(__MODULE__, {:push, item})
  end

  def pop do
    GenServer.call(__MODULE__, :pop)
  end

  # Server (callbacks)

  def init(:ok) do
    {:ok, :queue.new}
  end

  def handle_call(:pop, _from, queue) do
    {value, queue} = :queue.out(queue)
    {:reply, value, queue}
  end

  def handle_call(request, from, state) do
    # Call the default implementation from GenServer
    super(request, from, state)
  end

  def handle_cast({:push, item}, queue) do
    {:noreply, :queue.in(item, queue)}
  end

  def handle_cast(request, state) do
    super(request, state)
  end
end
