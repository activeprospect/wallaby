defmodule Wallaby.Phantom.Server do
  @moduledoc false
  use GenServer

  alias Wallaby.ProcessWorkspace

  @external_resource "priv/run_phantom.sh"
  @run_phantom_script_contents File.read! "priv/run_phantom.sh"

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [])
  end

  def stop(server) do
    GenServer.stop(server)
  end

  def get_base_url(server) do
    GenServer.call(server, :get_base_url, :infinity)
  end

  def get_local_storage_dir(server) do
    GenServer.call(server, :get_local_storage_dir, :infinity)
  end

  def clear_local_storage(server) do
    GenServer.call(server, :clear_local_storage, :infinity)
  end

  def init(_) do
    Process.flag(:trap_exit, true)
    port = find_available_port()
    {:ok, workspace_path} = ProcessWorkspace.create(self())

    setup_workspace(workspace_path)
    phantom_port = start_phantom(port, workspace_path)

    {:ok, %{running: false, awaiting_url: [], base_url: "http://localhost:#{port}/", workspace_path: workspace_path, port: phantom_port}}
  end

  defp setup_workspace(workspace_path) do
    create_local_storage_dir(workspace_path)
    write_wrapper_script(workspace_path)
  end

  defp create_local_storage_dir(workspace_path) do
    workspace_path |> local_storage_path |> File.mkdir_p!
  end

  defp write_wrapper_script(workspace_path) do
    path = wrapper_script_path(workspace_path)

    File.write!(path, @run_phantom_script_contents)
    File.chmod!(path,0o755)
  end

  defp start_phantom(port, workspace_path) do
    phantom_args = [
      "--webdriver=#{port}",
      "--local-storage-path=#{local_storage_path(workspace_path)}"
    ] ++ args(Application.get_env(:wallaby, :phantomjs_args, ""))

    start_port_with_wrapper_script(workspace_path, phantomjs_path(), phantom_args)
  end

  defp start_port_with_wrapper_script(workspace_path, path_to_executable, args) do
    # Starts phantomjs using the run_phantom.sh wrapper script so phantomjs will
    # be shutdown when stdin closes and when the beam terminates unexpectedly.
    Port.open({:spawn_executable, wrapper_script_path(workspace_path)},
            [:binary, :stream, :use_stdio, :exit_status, :stderr_to_stdout,
             args: [path_to_executable] ++ args])
  end

  defp find_available_port do
    {:ok, listen} = :gen_tcp.listen(0, [])
    {:ok, port} = :inet.port(listen)
    :gen_tcp.close(listen)
    port
  end

  defp local_storage_path(workspace_path) do
    Path.join(workspace_path, "local_storage")
  end

  defp wrapper_script_path(workspace_path) do
    Path.join(workspace_path, "wrapper")
  end

  defp phantomjs_path do
    Wallaby.phantomjs_path
  end

  defp args(phantomjs_args) when is_binary(phantomjs_args) do
    String.split(phantomjs_args)
  end

  defp args(phantomjs_args) when is_list(phantomjs_args) do
    phantomjs_args
  end

  def handle_info({_port, {:data, output}}, %{running: false} = state) do
    if output =~ "running on port" do
      Enum.each state.awaiting_url, &GenServer.reply(&1, state.base_url)
      {:noreply, %{state | running: true, awaiting_url: []}}
    else
      {:noreply, state}
    end
  end

  def handle_info({_port, {:exit_status, status}}, state) do
    {:stop, {:exit_status, status}, %{state | running: false}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def handle_call(:get_base_url, from, %{running: false} = state) do
    awaiting_url = [from|state.awaiting_url]
    {:noreply, %{state | awaiting_url: awaiting_url}}
  end

  def handle_call(:get_base_url, _from, state) do
    {:reply, state.base_url, state}
  end

  def handle_call(:get_local_storage_dir, _from, state) do
    {:reply, local_storage_path(state.workspace_path), state}
  end

  def handle_call(:clear_local_storage, _from, state) do
    result = state.workspace_path |> local_storage_path |> File.rm_rf

    {:reply, result, state}
  end

  def terminate(_reason, %{port: port} = state) do
    # IO.puts """
    # terminating #{__MODULE__} #{inspect self()}
    # #{inspect state}
    #
    # """
    %{os_pid: os_pid} = port |> Port.info |> Enum.into(%{})
    {microseconds, _} = :timer.tc fn ->
      Port.close(port)
      wait_for_stop(os_pid)
    end

    # IO.puts """
    # port closed #{__MODULE__} #{inspect self()} in #{microseconds/1000} ms
    # #{inspect state}
    #
    # """
  end

  defp wait_for_stop(os_pid) do
    if os_process_running?(os_pid) do
      Process.sleep(100)
      wait_for_stop(os_pid)
    end
  end

  defp os_process_running?(os_pid) do
    case System.cmd("kill", ["-0", to_string(os_pid)], stderr_to_stdout: true) do
      {_, 0} -> true
      _ -> false
    end
  end
end
