 defmodule GnExec.Cmd.Ls do
# TODO use behaviours

  @doc ~S"""
  Description

      iex> #GnExec.Cmd.GrepWc.cmd("QTL","README.md","result.out")
      :notimplemented

  """
  def script(directory, parameters \\ '') do
    """

echo "This is a test string written to a file on the current working directory" > echo_test.txt
ls #{parameters} #{directory}
sleep 10
ls #{parameters} #{directory}
touch send_file_created.txt

"""
  end
end
