
requile Logger
# Place jobs in the server queue.
home_path =System.user_home()<>"/"
File.ls!(home_path)|> Enum.filter(&File.dir?(home_path<>&1)) |> Enum.each(fn(dir)->
  absdir=home_path<>dir
  Logger.info "Creating job for #{absdir}"
  {:ok, job} = GnExec.Job.new("Ls", [absdir])
  Logger.info "Submitting job for #{dir} with token #{job.token}"
  GnExec.Rest.Job.submit(job)
end)

# This should be a kind of giant loop running on the cluster node.

defmodule GnExec.Node do

  def run do
    :timer.sleep(:timer.seconds(1))
    #Get the job from the remote gn_server
    case GnExec.Rest.Job.get do
      :empty -> :empty
      job ->
        # Local:place the job in the queue
        GnExec.Registry.put job
        {j, status} = GnExec.Registry.next

        output_callback = fn(data) ->
          # Dump data locally STDOUT and progress
          GnExec.Job.stdout(:write, j, data)
          progress = GnExec.Job.progress(:read, j).progress + 1
          GnExec.Job.progress(:write, j, progress)
          # Place the STDOUT and progress remotely
         GnExec.Rest.Job.set_status(j, progress)
         GnExec.Rest.Job.update_stdout(j,data)
        end

        transfer_callback = fn(job, file)->
         GnExec.Rest.Job.transfer_file(j, file)
          :ok # returning :ok means that locally everything is fine and the job can change state from running to transferred
        end

        # Dump locally the returning value and in case place it remotely
        # Currently the remote result is not kept
        retval_callback = fn(retval) ->
          GnExec.Job.retval(:write, j, retval)
          GnExec.Rest.Job.set_retval(j, retval)
        end

        # Run the job with callbacks
        GnExec.Registry.run(j.token, output_callback, transfer_callback, retval_callback)
        :run
    end
    run
  end
end
GnExec.Node.run
