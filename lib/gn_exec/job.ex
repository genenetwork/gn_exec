defmodule GnExec.Job do
  # use GenServer
  defstruct [:token, :command, :args, :path, :module]

  def new(command, args \\ [] ) do
    case validate(command) do
      {:ok, module } ->
        {:ok, %GnExec.Job{
                token: token(command, args),
                command: command,
                args: args,
                path: Application.get_env(:gn_exec, :jobs_path_prefix),
                module: module
               }
             }
      error -> error
    end
  end

  # def new(command, [""]) do
  #   new(command, [])
  # end
  #
  # def new(command, "") do
  #   new(command, [])
  # end


  # @doc ~S"""
  # Spawn a Job with a given command and default arguments
  # TODO: add the process to a supervisor
  #
  # iex> GnExec.Job.start_link "Ls"
  # {:ok, "b20267df989b21456a90195b14b8894d32feec06b28f66463760bc78df5483bd"}
  #
  # """
  # def start_link(command, args \\ [] ) do
  #   case new(command, args) do
  #     {:ok, job} ->
  #       if GnExec.Registry.has_job? job do
  #         {:ok, job.token}
  #       else
  #         {:ok, pid} = GenServer.start_link(__MODULE__, {job, :queued})
  #         GnExec.Registry.put(job, pid)
  #         {:ok, job.token}
  #       end
  #     error -> error
  #   end
  # end
  # def start_link(job) do
  #   GenServer.start_link(__MODULE__, {job, :queued})
  # end


  # @doc ~S"""
  # Get the stage/queue of the process
  #
  # ## Examples
  #
  # iex> #{:ok, token} = GnExec.Job.start_link "Ls"
  # iex> #GnExec.Job.stage token
  # :x
  #
  # """
  # def stage(token) do
  #   case GnExec.Registry.get(token) do
  #     {:ok, pid} -> GenServer.call(pid, :stage)
  #     :error -> :error
  #   end
  # end

  # @doc ~S"""
  # Get the Job object from the token
  # """
  # def get(token) do
  #   case GnExec.Registry.get(token) do
  #     {:ok, pid} -> GenServer.call(pid, :get)
  #     :error -> :error
  #   end
  # end

  def validate(command) do
    case Code.ensure_loaded(Module.concat([GnExec,Cmd,command])) do
      {:module, module } ->
        {:ok, module }
      {:error, :nofile} ->
        {:error, :noprogram}
    end
  end

  def progress(:read, job) do
    static_path = Application.get_env(:gn_exec, :jobs_path_prefix)
    status_path = Path.join(static_path, job.token)
    case File.exists?(status_path) do
      false -> :enote # file does not exist
      true ->
        status_path_file = Path.join(status_path, "progress.json")
        Poison.Parser.parse!(File.read!(status_path_file),keys: :atoms!)
    end
  end

  def progress(:write, job, value) do
    static_path = Application.get_env(:gn_exec, :jobs_path_prefix)
    status_path = Path.join(static_path, job.token)
    case File.exists?(status_path) do
      false -> :enote # file does not exist
      true ->
        status_path_file = Path.join(status_path, "progress.json")
        File.write(status_path_file, Poison.encode!(%{progress: value}), [:binary])
        :ok
    end
  end

  def stdout(:read, job) do
    static_path = Application.get_env(:gn_exec, :jobs_path_prefix)
    status_path = Path.join(static_path, job.token)
    case File.exists?(status_path) do
      false -> :enote # file does not exist
      true ->
        status_path_file = Path.join(status_path, "STDOUT")
        File.read!(status_path_file)
    end
  end

  def stdout(:write, job, value) do
    static_path = Application.get_env(:gn_exec, :jobs_path_prefix)
    status_path = Path.join(static_path, job.token)
    case File.exists?(status_path) do
      false -> :enote # file does not exist
      true ->
        status_path_file = Path.join(status_path, "STDOUT")
        File.write!(status_path_file, value, [:binary, :append])
        :ok
    end
  end

  def retval(:read, job) do
    static_path = Application.get_env(:gn_exec, :jobs_path_prefix)
    status_path = Path.join(static_path, job.token)
    case File.exists?(status_path) do
      false -> :enote # file does not exist
      true ->
        status_path_file = Path.join(status_path, "retval.json")
        Poison.Parser.parse!(File.read!(status_path_file),keys: :atoms!)
    end
  end

  def retval(:write, job, value) do
    static_path = Application.get_env(:gn_exec, :jobs_path_prefix)
    status_path = Path.join(static_path, job.token)
    case File.exists?(status_path) do
      false -> :enote # file does not exist
      true ->
        status_path_file = Path.join(status_path, "retval.json")
        File.write(status_path_file, Poison.encode!(%{retval: value}), [:binary])
        :ok
    end
  end


  @doc ~S"""
  Set up the directory, in case it already exists just notify that at the user
  """
  def setupdir(job) do # TODO: is it better to have path inside or as parameter ?
    static_path = Application.get_env(:gn_exec, :jobs_path_prefix)
    path = Path.join(static_path, job.token)
    IO.puts path
    response = case File.exists?(path) do
    true ->
      :exists
    false ->
      File.mkdir_p(path)
      File.touch!(Path.join(path,"STDOUT"))
      File.touch!(Path.join(path,"progress.json"))
      progress(:write, job, 0)
      :ok
    end
    IO.puts response
    response
  end

  def run(job, output_callback, transfer_callback, retval_callback) do
    GnExec.Executor.exec_async job,
                               output_callback,
                               transfer_callback,
                               retval_callback
  end


  # @doc ~S"""
  # Set the state of the process to running
  # """
  # def running(token) do
  #   case stage(token) do
  #     :queued ->
  #   end
  # end

  @doc ~S"""
  Generate a token for a command

  token = "8412ab517c6ef9c2f8b6dae3ed2a60cc"
  cache_dir = Application.get_env(:gn_server, :cache_dir)
  """
  defp token(command, args) do
    #:crypto.rand_bytes(32)
    # SecureRandom.hex(32)
    :crypto.hash(:sha256, [command | args]) |> Base.encode16 |> String.downcase
  end

# # Server calls
#   def handle_call(:stage, _from, {_job, stage} = state) do
#     {:reply, stage, state}
#   end
#
#   def handle_call(:get, _from, {job, _} = state) do
#     {:reply, job, state}
#   end
end
