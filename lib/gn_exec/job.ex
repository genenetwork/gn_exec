defmodule GnExec.Job do
  defstruct [:token, :command, :args]

  def new(command, [""]) do
    new(command, [])
  end

  def new(command, "") do
    new(command, [])
  end

  def new(command, args \\ [] ) do
    #  when {:module, _} ==
    # Todo validate command
        %GnExec.Job{
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

  @doc ~S"""
  Generate a token for a command

  token = "8412ab517c6ef9c2f8b6dae3ed2a60cc"
  cache_dir = Application.get_env(:gn_server, :cache_dir)
  """
  defp token(command, args \\ []) do
    #:crypto.rand_bytes(32)
    # SecureRandom.hex(32)
    :crypto.hash(:sha256, [command | args]) |> Base.encode16 |> String.downcase
  end

end
