defmodule GnExec.Rest.JobStatus do
  defstruct [:progress]
end

defmodule GnExec.Rest.Job do
  require Logger
  use HTTPoison.Base
  # @derive [Poison.Encoder]

  @type command :: String.t
  @type arguments :: no_argument|[String.t]
  @type no_argument :: []
  @type token :: String.t

  # defstruct token: "", command: "" , arguments: []



  def process_url(url) do
    server_url = Application.get_env(:gn_exec, :gn_server_url)
    Logger.info server_url <> url
    server_url <> url
  end



# programs does not require parameters, actually jobs are jobs+arguments+data
# there is no need to provide any data or parameters
  def get do
    # GnExec.Rest.Client.get_a_job(program)
    response = get!("").body
    |> Poison.decode!(as: %GnExec.Job{})
    # Here a with is more than helpful
    case response do
      "empty" -> :empty
      # passing back and forth the data are converted into strings by json
      job -> %{%{job | module: String.to_atom(job.module)} | args: case is_list(job.args) do
        true -> job.args
        false -> String.split(job.args)
      end}
# TODO validate the incoming command
      #   case validate(job.command) do
      #   {:ok, module} ->
      #   {:error, reason} -> reason
      #
      # end
    end

  end

  ### TODO: submit a new job to the queue.
  def submit(job) do
    Logger.debug "Rest.Job.submit #{job.token}"
    Logger.debug "Rest.Job.submit #{job.command}"
    # body =
    # IO.inspect body
    post!(job.command, {:form, [
                                 {:arguments, Base.encode64(Poison.encode!(job.args))},
                                 {:token, job.token}
                               ]}).body
          |> Poison.decode!
  end

  def status(job) do
    # GnExec.Rest.Client.get_status(job.token)
    get!("program/" <> job.token <> "/progress.json").body
    |> Poison.decode!(as: %GnExec.Rest.JobStatus{} )
  end

  def status(job, progress) do
    # GnExec.Rest.Client.set_status(job.token, progress)
    put!("program/" <> job.token <> "/progress.json",{:form, [{:progress, progress}]})
  end

  def stdout(job, stdout) do
    # GnExec.Rest.Client.update_stdout(job.token, stdout)
    put!("program/" <> job.token <> "/STDOUT",{:form, [{:stdout, stdout}]})
  end

  def retval(job, retval) do
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

  def transfer_file(job, filename) do
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

end
