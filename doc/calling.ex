# Create a job locally
#{:ok, job} = GnExec.Job.new("Ls", ["."])
#{:ok, job} = GnExec.Job.new "Lmmpy", ["/Users/bonnalraoul/Documents/Projects/gn/pylmm_gn2/data/test8000.geno", "/Users/bonnalraoul/Documents/Projects/gn/pylmm_gn2/data/test8000.pheno"]
# Post the job on the gn_server ready to be deployed somewhere
#  GnExec.Rest.Job.submit(job)

# Place jobs in the server queue.
home_path =System.user_home()<>"/"
File.ls!(home_path)|> Enum.filter(&File.dir?(home_path<>&1)) |> Enum.each(fn(dir)->
  absdir=home_path<>dir
  IO.puts "Creating job for #{absdir}"
  {:ok, job} = GnExec.Job.new("Ls", [absdir])
  IO.puts "Submitting job for #{dir} with token #{job.token}"
  GnExec.Rest.Job.submit(job)
end)


# This should be a kind of giant loop running on the cluster node.

defmodule GnExec.Node do

  def run do
    :timer.sleep(:timer.seconds(5))
    #Get the job from the remote gn_server
    case GnExec.Rest.Job.get do
      :empty -> :empty
      job ->
        # Local:place the job in the queue
        GnExec.Registry.put job
        {j, status} = GnExec.Registry.next

        output_callback = fn(data) ->
        # Dump data locally STDOUT and progress
        # Place the STDOUT and progress remotely
          GnExec.Job.stdout(:write, j, data)
          progress = GnExec.Job.progress(:read, j).progress + 1
          GnExec.Job.progress(:write, j, progress)
          GnExec.Rest.Job.set_status(j, progress)
          GnExec.Rest.Job.update_stdout(j,data)
        end

        transfer_callback = fn(job, file)->
          GnExec.Rest.Job.transfer_file(j, file)
          # check is everything is ok.
          GnExec.Registry.transferred j.token
        end

        # Dump locally the returning value and in case place it remotely
        retval_callback = fn(retval) ->
          GnExec.Job.retval(:write, j, retval)
          GnExec.Rest.Job.set_retval(j, retval)
          # TODO: mark the job complete
        end

        # Run the job with callbacks
        GnExec.Registry.run(j.token, output_callback, transfer_callback, retval_callback)
        :run
    end
    run
  end
end
GnExec.Node.run
