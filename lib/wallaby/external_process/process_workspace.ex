defmodule Wallaby.ExternalProcess.ProcessWorkspace do
  @moduledoc false

  # Creates a workspace for a process
  # that will be cleaned up after the process goes down.

  defmodule ServerSupervisor do
    @moduledoc false
    use Supervisor

    alias Wallaby.ExternalProcess.ProcessWorkspace.Server

    def start_link do
      Supervisor.start_link(__MODULE__, [], name: __MODULE__)
    end

    def start_server(process_pid, tmp_path) do
      Supervisor.start_child(__MODULE__, [process_pid, tmp_path])
    end

    @impl Supervisor
    def init([]) do
      children = [
        worker(Server, [], restart: :transient)
      ]
      supervise(children, strategy: :simple_one_for_one)
    end
  end

  @spec create(pid, String.t) :: {:ok, String.t}
  def create(process_pid, tmp_path \\ gen_tmp_path) do
    {:ok, pid} = ServerSupervisor.start_server(process_pid, tmp_path)
    {:ok, tmp_path}
  end

  @spec gen_tmp_path :: String.t
  defp gen_tmp_path do
    dirname = Integer.to_string(:rand.uniform(0x100000000), 36) |> String.downcase

    Path.join(System.tmp_dir!, dirname)
  end
end
