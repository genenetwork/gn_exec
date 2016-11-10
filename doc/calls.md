# Create a job locally
{:ok, job} = GnExec.Job.new("Ls", ["."])

# Post the job on the gn_server ready to be deployed somewhere
  GnExec.Rest.Job.submit(job)

#Get the job from the remote gn_server
job = GnExec.Rest.Job.get

# This should be a kind of giant loop
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

# Dump locally the returning value and in case place it remotely
retval_callback = fn(retval) ->
  GnExec.Job.retval(:write, j, retval)
  GnExec.Rest.Job.set_retval(j, retval)
  # TODO: mark the job complete
  GnExec.Registry.complete j.token
end

# Run the job with callbacks
GnExec.Registry.run(j.token, output_callback, &GnExec.Rest.Job.transfer_file/2, retval_callback)

#
GnExec.Job.run(job, fn(x)-> nil end,  fn(x)-> nil end)
