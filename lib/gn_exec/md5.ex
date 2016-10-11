defmodule GnExec.Md5 do
# credits
# https://github.com/everpeace/programming-erlang-code/blob/master/code/lib_md5.erl

#%% md5:file works with chunks so should work correctly with extremely
#%% large files

  @blocksize 32768

  def file(filename) do
    case File.open(filename, [:binary,:read, {:read_ahead, @blocksize}]) do
      {:ok, file} -> loop(file, :erlang.md5_init())
      {:error, reason}   -> reason
    end
  end

  defp loop(file, checksum) do
    case IO.read(file, @blocksize) do
    {:error, reason} ->
      File.close(file)
      reason
    :eof ->
      File.close(file)
	    {:ok, Base.encode16(:erlang.md5_final(checksum), case: :lower)}
    data ->
      loop(file, :erlang.md5_update(checksum, data))
    end
  end

end
