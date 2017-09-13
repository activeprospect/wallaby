defmodule Wallaby.ExternalProcess do
  @moduledoc false
  use GenServer

  defstruct port: nil
  @type t :: %__MODULE__{
    port: port
  }

  def start_link(path_to_executable, args \\ []) do
    GenServer.start_link(__MODULE__, [path_to_executable, args])
  end

  def get_os_pid(server) do
    GenServer.call(server, :get_os_pid)
  end

  def stop(server) do
    GenServer.stop(server)
  end

  @impl GenServer
  def init([path_to_executable, args]) do
    try do
      Port.open({:spawn_executable, path_to_executable},
        [:binary, :stream, :use_stdio, :exit_status, args: args])
    rescue
      e in [ErlangError] ->
        {:stop, e.original}
    else
      port ->
        {:ok, %__MODULE__{port: port}}
    end
  end

  @impl GenServer
  def handle_call(:get_os_pid, _from, %__MODULE__{port: port} = state) do
    os_pid =  port |> Port.info |> Keyword.fetch!(:os_pid)

    {:reply, os_pid, state}
  end

  @impl GenServer
  def handle_info({port, {:exit_status, _}}, %__MODULE__{port: port} = state) do
    {:stop, :crashed, state}
  end
  def handle_info(msg, state), do: super(msg, state)
end
