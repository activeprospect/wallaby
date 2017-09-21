defmodule Wallaby.ExternalProcess do
  @moduledoc false
  use GenServer

  alias __MODULE__.State

  defstruct [:port]
  @type t :: %__MODULE__{
    port: nil | port
  }

  @external_resource "priv/run_phantom.sh"
  @run_cmd_script_contents File.read! "priv/run_phantom.sh"

  @type start_link_opt :: {:wrapper_script_contents, String.t}

  @spec start_link(String.t, [String.t], [start_link_opt]) :: GenServer.on_start
  def start_link(path_to_executable, args \\ [], opts \\ []) do
    wrapper_script_contents = Keyword.get(opts, :wrapper_script_contents,
     @run_cmd_script_contents)

    GenServer.start_link(__MODULE__, [path_to_executable, args,
      wrapper_script_contents])
  end

  def get_os_pid(server) do
    GenServer.call(server, :get_os_pid)
  end

  def get_wrapper_script_path(server) do
    GenServer.call(server, :get_wrapper_script_path)
  end

  def stop(server) do
    GenServer.stop(server)
  end

  @impl GenServer
  def init([path_to_executable, args, wrapper_script_contents]) do
    Process.flag(:trap_exit, true)
    state = State.new

    try do
      write_wrapper_script(state, wrapper_script_contents)
      wrapper_path = State.wrapper_script_path(state)

      Port.open({:spawn_executable, wrapper_path},
        [:binary, :stream, :use_stdio, :exit_status,
         args: [path_to_executable | args]])
    rescue
      e in [ErlangError] ->
        {:stop, e.original}
    else
      port ->
        {:ok, %{state | port: port}}
    end
  end

  @impl GenServer
  def handle_call(:get_os_pid, _from, %State{port: port} = state) do
    os_pid =  port |> Port.info |> Keyword.fetch!(:os_pid)
    {:reply, os_pid, state}
  end
  def handle_call(:get_wrapper_script_path, _from, state) do
    path = State.wrapper_script_path(state)
    {:reply, path, state}
  end

  @impl GenServer
  def handle_info({port, {:exit_status, _}}, %__MODULE__{port: port} = state) do
    {:stop, :crashed, state}
  end
  def handle_info(msg, state), do: super(msg, state)

  @impl GenServer
  def terminate(_reason, %State{port: port, tmp_dir: tmp_dir}) do
    # Port.close(port)
    File.rm_rf!(tmp_dir)
  end

  defp write_wrapper_script(state, script_contents) do
    File.mkdir(state.tmp_dir)
    wrapper_script_path = State.wrapper_script_path(state)

    :ok = File.write(wrapper_script_path, script_contents)
    :ok = File.chmod(wrapper_script_path, 0o755)
  end
end
