defmodule Wallaby.ExternalProcess.ProcessWorkspace.Server do
  @moduledoc false
  use GenServer

  def start_link(process_pid, tmp_path) do
    GenServer.start_link(__MODULE__, [process_pid, tmp_path])
  end

  def tmp_dir(pid) do
    GenServer.call(pid, :tmp_dir)
  end

  @impl GenServer
  def init([process_pid, tmp_dir]) do
    ref = Process.monitor(process_pid)
    :ok = File.mkdir(tmp_dir)

    {:ok, %{ref: ref, tmp_dir: tmp_dir}}
  end

  @impl GenServer
  def handle_call(:tmp_dir, _from, %{tmp_dir: tmp_dir} = state) do
    {:reply, tmp_dir, state}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, _object, _reason}, %{ref: ref, tmp_dir: tmp_dir}) do
    File.rm_rf(tmp_dir)
    {:stop, :normal, ref}
  end
  def handle_info(msg, state), do: super(msg, state)
end
