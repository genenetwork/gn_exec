# defmodule GnExec.Registry.JobSupervisor do
#   use Supervisor
#
#   def start_link do
#     Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
#   end
#
#   def init([]) do
#     children = [
#
#     ]
#
#     # supervise/2 is imported from Supervisor.Spec
#     supervise(children, strategy: :one_for_one)
#   end
#
# end
#

defmodule GnExec.Registry do
  use GenServer
  alias GnExec.Job

  # Client

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def put(job) do
    GenServer.cast(__MODULE__, {:put, job})
  end

  def has_job?(token) do
    GenServer.call(__MODULE__, {:has_job?, token})
  end

  def get(token) do
    GenServer.call(__MODULE__, {:get, token})
  end

  def status(token) do
    GenServer.call(__MODULE__, {:status, token})
  end

  def pop(token) do
    GenServer.call(__MODULE__, {:pop, token})
  end

  def run?(token) do
    GenServer.call(__MODULE__, {:run?, token})
  end

  def run(token,
          output_callback \\ fn(_x)-> nil end,
          transfer_callback \\ fn(_job, _packfile)-> nil end ,
          retval_callback \\ fn(_x)-> nil end) do
    GenServer.cast(__MODULE__, {:run, token, output_callback, transfer_callback, retval_callback})
  end

  @doc ~S"""
  Just mark the token/job with the running atom
  """
  def mark(token, :running) do
    GenServer.call(__MODULE__, {:mark, token, :running})
  end


  def complete(token) do
    GenServer.cast(__MODULE__, {:complete, token})
  end

  def transferred(token) do
    GenServer.cast(__MODULE__, {:transferred, token})
  end


  def error(token) do
    GenServer.cast(__MODULE__, {:error, token})
  end


  @doc ~S"""
  Get the next job queued from the queue and set it as requested
  """
  def next do
    GenServer.call(__MODULE__, :next)
  end

  @doc ~S"""
  Read the progress of a job (progress.json)
  """
  def progress(:read, token) do
    GenServer.call(__MODULE__, {:progress, {:read, token}})
  end

  def stdout(:read, token) do
    GenServer.call(__MODULE__, {:stdout, {:read, token}})
  end


  def retval(:read, token) do
    GenServer.call(__MODULE__, {:retval, {:read, token}})
  end

  @doc ~S"""
  Write the progress for a job (progress.json)
  """
  def progress(:write, token, value) do
    GenServer.cast(__MODULE__, {:progress, {:write, token, value}})
  end

  def stdout(:write, token, data) do
    GenServer.cast(__MODULE__, {:stdout, {:write, token, data}})
  end

  def retval(:write, token, data) do
    GenServer.cast(__MODULE__, {:retval, {:write, token, data}})
  end


  # Server (callbacks)

  def init(:ok) do
    # FIFO queue, requested, running, completed
    # if a job is get from the queue, it is returned and placed in the requrested MAP
    # once we have the confirmation that someone start computing it we can place it into the running Map
    # when someone finish to compute it, we place it in the completed Map
    # Running can have the same job multiple times, completed
    # {:ok, supervisor } = GnExec.Registry.JobSupervisor.start_link
    # {:ok, {supervisor, Map.new }}
    {:ok, {Map.new, :queue.new}}
  end

  def handle_call({:has_job?, token}, _from, {map, _queue } = state) do
    {:reply, Map.has_key?(map, token), state}
  end

  def handle_call({:get, token}, _from, {map, _queue} = state) do
    {:reply, Map.fetch(map, token), state}
  end

  def handle_call({:status, token}, _from, {map, _queue} = state) do
    {:ok, {_job, status}} = Map.fetch(map, token)
    {:reply, status , state}
  end


  def handle_call({:pop, token}, _from, {map, queue}) do
    # remove the token from the registry and from the queue
    queue = :queue.filter(fn(item)->
      !(token === item)
    end, queue)
    {value, map} = Map.pop(map, token)
    {:reply, value, {map, queue}}
  end

  def handle_call({:run?, token}, _from, {map, _queue} = state) do
    case Map.get(map, token) do
      nil -> {:reply, :enote, state} # not exists
      {_job, :running} -> {:reply, true, state}
      {_job, status} -> {:reply, {false, status}, state }
    end
  end


  def handle_cast({:run, token, output_callback, transfer_callback, retval_callback}, {map, queue} = state) do
    case Map.get(map, token) do
      { job, :requested} ->
        Job.setupdir(job) # Create the directories before setting the stare to running
        Job.run(job, output_callback, transfer_callback, retval_callback)
        {:noreply, {Map.put(map, token, {job, :running}), queue}}
      _ -> {:noreply, state }
    end
  end

  def handle_cast({:transferred, token}, {map, queue} = state) do
    case Map.get(map, token) do
      {job, :running} -> {:noreply, {Map.put(map, token, {job, :transferred}), queue }}
      nil -> {:noreply, state} # not exists
      #{_job, _status} -> {:noreply, state }
    end
  end

  def handle_cast({:complete, token}, {map, queue} = state) do
    x = Map.get(map, token)
    IO.inspect x
    case Map.get(map, token) do
      {job, :transferred} -> {:noreply, {Map.put(map, token, {job, :complete}), queue }}
      nil -> {:noreply, state} # not exists
      #{_job, _status} -> {:noreply, state }
    end
  end


  def handle_cast({:error, token}, {map, queue} = state) do
    case Map.get(map, token) do
      {job, :running} -> {:noreply, {Map.put(map, token, {job, :error}), queue }}
      nil -> {:noreply, state} # not exists
      {_job, _status} -> {:noreply, state }
    end
  end


  def handle_call(:next, _from, {map, queue} = state) do
    case :queue.out(queue) do
      {:empty, _queue } ->
        {:reply, :empty, state }
      {{:value, token}, queue} ->
        case Map.get(map, token) do
          nil -> {:reply, :enote, state} # not exists
          {job, :queued} -> {:reply, {job, :requested}, {Map.put(map, token, {job, :requested}), queue }}
        end
    end
  end

  def handle_call({:progress, {:read, token}}, _from, {map, _queue} = state) do
    case Map.fetch(map, token) do
      :error -> {:reply, :enote, state}
      {:ok, {job, _status}} -> {:reply, Job.progress(:read, job), state}
    end
  end

  def handle_call({:stdout, {:read, token}}, _from, {map, _queue} = state) do
    case Map.fetch(map, token) do
      :error -> {:reply, :enote, state}
      {:ok, {job, _status}} -> {:reply, Job.stdout(:read, job), state}
    end
  end

  def handle_call({:retval, {:read, token}}, _from, {map, _queue} = state) do
    case Map.fetch(map, token) do
      :error -> {:reply, :enote, state}
      {:ok, {job, _status}} -> {:reply, Job.retval(:read, job), state}
    end
  end

  def handle_call({:mark, token, :running}, _from, {map, queue} = state) do
    case Map.fetch(map, token) do
      {:ok, {job, :requested}} ->
        {:reply, :ok, {Map.put(map, token, {job, :running}), queue}}
      {:ok, {_job, status}} ->
        {:reply, status, state}
      :error ->
        {:reply, :enote, state}
    end
  end



  def handle_call(request, from, state) do
    # Call the default implementation from GenServer
    super(request, from, state)
  end

  def handle_cast({:put, job}, {map, queue}) do
    # import Supervisor.Spec, warn: false
    if !Map.has_key?(map, job.token) do
      # {:ok, job_pid} = GnExec.Job.start_link job
      # {:ok, pid} = Supervisor.start_child(supervisor, {GnExec.Job, {GnExec.Job, :start_link, [job]}, :transient, 5000, :worker, [GnExec.Job]})
      {:noreply, {Map.put(map, job.token, {job, :queued}), :queue.in(job.token, queue)}}
    else
      {:noreply, {map, queue}}
    end
  end

  def handle_cast({:progress, {:write, token, value}}, {map, _queue} = state) do
    case Map.fetch(map, token) do
      {:ok, {job, :running}} ->
        # TODO: a function could evaluate if the update is ok or not.
        Job.progress(:read, job)
        Job.progress(:write, job, value)
      :error -> :error
    end
    {:noreply, state}
  end

  def handle_cast({:stdout, {:write, token, value}}, {map, _queue} = state) do
    case Map.fetch(map, token) do
      {:ok, {job, :running}} ->
        # TODO: a function could evaluate if the update is ok or not.
        Job.stdout(:write, job, value)
      :error -> :error
    end
    {:noreply, state}
  end

  def handle_cast({:retval, {:write, token, value}}, {map, _queue} = state) do
    case Map.fetch(map, token) do
      {:ok, {job, :transferred}} ->
        # TODO: a function could evaluate if the update is ok or not.
        Job.retval(:write, job, value)
      :error -> :error
    end
    {:noreply, state}
  end


  # def handle_cast(request, state) do
  #   super(request, state)
  # end
end
