defmodule GnExec.RegistryTest do
  # TODO: clean up on the Registry it is important in case of job terminates
  use ExUnit.Case, async: false
  alias GnExec.Registry
  alias GnExec.Job

  setup do
    on_exit fn ->
      Registry.wipeout
    end
  end

  test "Store a job" do
    {:ok, job} = Job.new "Ls"
    assert Registry.put(job) == :ok
  end


  test "Remove a job and its state from the Registry" do
    {:ok, job} = Job.new "Ls", ["xx"]
    Registry.put job
    assert Registry.pop(job.token) === {%GnExec.Job{args: ["xx"], command: "Ls", module: GnExec.Cmd.Ls,
             path: "test/data/input",
             token: "6480d6a7cccb65dfb6f9af9cdc9b3df01f973d23f7686f28ade217b8643dbe59"},
            :queued}
    assert false == Registry.has_job? job.token
  end

  test "Get a job with state from the Registry " do
    {:ok, job} = Job.new "Ls", ["xxx"]
    Registry.put job
    assert Registry.get(job.token) === {:ok, {%GnExec.Job{args: ["xxx"], command: "Ls", module: GnExec.Cmd.Ls,
             path: "test/data/input",
             token: "a3caea55ed4877e43c7996999ac56f2658d2cafa13bf5c519524d0d5f9c6d43d"},
            :queued}}
  end

  # test "Get a job from an empty registry" do
  #   assert :empty == Registry.next
  # end

  test "Get job status" do
    {:ok, job} = Job.new "Ls", ["xxxy"]
    Registry.put job
    assert :queued == Registry.status(job.token)
  end


  test "Set a job to running" do
    {:ok, job} = Job.new "Ls", [""]
    Registry.put job
    assert {job, :requested} = Registry.next
    assert :ok == Registry.run(job.token)
    assert true == Registry.run?(job.token)
  end
  #
  # test "Try to set a running process when is in the queue" do
  #   {:ok, job} = Job.new "Ls", ["-","ds"]
  #   Registry.put job
  #   assert :ok == Registry.run(job.token)
  #   assert  {false, :queued} == Registry.run?(job.token)
  # end
  #
  #
  # test "Try to set a running process to running again" do
  #   {:ok, job} = Job.new "Ls", [""]
  #   Registry.put job
  #   assert {job, :requested} = Registry.next
  #   assert :ok == Registry.run(job.token)
  # end
  #
  #
  # # test "Job get its stage" do
  # #   {:ok, token} = GnExec.Job.start_link "Ls"
  # #   assert GnExec.Job.stage(token) == :queued
  # # end
  # #
  # # test "Job get the job object" do
  # #   {:ok, token} = GnExec.Job.start_link "Ls", ["param1"]
  # #   assert GnExec.Job.get(token) === %GnExec.Job{args: ["param1"], command: "Ls", path: ".",
  # #           token: "351cbc9990db5647424a1ece1c1e66ed36dfa8afcc181803fbff81962dc24dae"}
  # # end
  #
end
