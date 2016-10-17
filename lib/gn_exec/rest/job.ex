defmodule GnExec.Rest.JobStatus do
  defstruct [:progress]
end


defmodule GnExec.Rest.Job do
  use HTTPoison.Base
  # @derive [Poison.Encoder]

  @type command :: String.t
  @type arguments :: no_argument|[String.t]
  @type no_argument :: []
  @type token :: String.t

  # defstruct token: "", command: "" , arguments: []
  defstruct [:token, :command, :args]


  def process_url(url) do
    server_url = Application.get_env(:gn_exec, :gn_server_url)
    server_url <> url
  end


  def new(command, args \\ [] ) do
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

# programs does not require parameters, actually jobs are jobs+arguments+data
# there is no need to provide any data or parameters
  def get(program) do
    # GnExec.Rest.Client.get_a_job(program)
    get!(program <> "/dataset.json").body
    |> Poison.decode!(as: %GnExec.Rest.Job{})
  end

  #@spec run(job :: GnExec.Rest.Job) :: any
  def run(job) do
    set_status(job, 0)
# you can define any function/callback that will be called every time a new data will be produced
    output_callback = fn(data) ->
      # TODO: Here user can also update the state of the jobs increasing and/or modifying it
      status = status(job)
      update_stdout(job, data)
      set_status(job, status.progress + 1)
    end


    case validate(job.command) do
      {:ok, module } ->
        task = GnExec.Executor.exec_async module,
                                          job,
                                          output_callback,
                                          &transfer_file/2
      {:error, :noprogram} -> {:error, :noprogram}
    end
  end

  def status(job) do
    # GnExec.Rest.Client.get_status(job.token)
    get!("program/" <> job.token <> "/status.json").body
    |> Poison.decode!(as: %GnExec.Rest.JobStatus{} )
  end

  def set_status(job, progress) do
    # GnExec.Rest.Client.set_status(job.token, progress)
    put!("program/" <> job.token <> "/status.json",{:form, [{:progress, progress}]})
  end

  def update_stdout(job, stdout) do
    # GnExec.Rest.Client.update_stdout(job.token, stdout)
    put!("program/" <> job.token <> "/STDOUT",{:form, [{:stdout, stdout}]})
  end

  def set_retval(job, retval) do
    # GnExec.Rest.Client.set_retval(job.token, retval)
    put!("program/" <> job.token <> "/retval.json",{:form, [{:retval, retval}]})
  end

  def transfer_files(job, path) do
    File.ls!(path)
    |> Enum.map( fn(file) ->
      # TODO need to collect responses from remote server to do something else?
      transfer_file(job, Path.join(path, file )).body
      |> Poison.decode!
    end
    )
  end

  defp transfer_file(job, filename) do
    # TODO compute the checksum for each file, it is not possible to know at priori the size of the file.
    {:ok, checksum} = GnExec.Md5.file(filename)
    post!("program/" <> job.token ,
                     {:multipart, [
                       {"name", "file"},
                       {:file, filename},
                       {"checksum", checksum}
                       ]
                       },
                     [{"Accept", "application/json"}]
                     )
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
