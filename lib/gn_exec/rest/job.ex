defmodule GnExec.Rest.Job do
  # @derive [Poison.Encoder]

  @type command :: String.t
  @type arguments :: no_argument|[String.t]
  @type no_argument :: []
  @type token :: String.t

  # defstruct token: "", command: "" , arguments: []
  defstruct [:token, :command, :args]


  def new(command, args) do
    #  when {:module, _} ==
    # Todo validate command
        %GnExec.Rest.Job{
          token: token(command, args),
          command: command,
          args: args
         }
  end

  def validate(command) do
    case Code.ensure_loaded(Module.concat([GnExec,Cmd,command])) do
      {:module, module } ->
        {:ok, module }
      {:error, :nofile} ->
        {:error, :noprogram}
    end
  end

  def get(program, parameter) do
    GnExec.Rest.Client.get_a_job(program, parameter)
  end

  def run(job) do
    case validate(job.command) do
      {:ok, module } ->
        task = GnExec.Executor.exec_async module, job.args
        Task.await(task)
      {:error, :noprogram} -> {:error, :noprogram}
    end
  end

  def status(job) do
    GnExec.Rest.Client.get_status(job.token)
  end

  def set_status(job, progress) do
    GnExec.Rest.Client.set_status(job.token, progress)
  end

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


end

defmodule GnExec.Rest.JobStatus do
  defstruct [:progress]
end
