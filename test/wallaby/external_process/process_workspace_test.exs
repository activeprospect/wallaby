defmodule Wallaby.ExternalProcess.ProcessWorkspaceTest do
  use ExUnit.Case, async: true

  alias Wallaby.ExternalProcess.ProcessWorkspace

  defmodule TestServer do
    use GenServer

    def start, do: GenServer.start(__MODULE__, [])
    def stop(pid), do: GenServer.stop(pid)

    @impl GenServer
    def init([]), do: {:ok, []}
  end

  describe "create/1" do
    test "creates a workspace at the given folder which is deleted after the process ends" do
      {:ok, pid} = TestServer.start()
      {:ok, tmp_dir} = ProcessTemp.create(pid)

      assert File.exists?(tmp_dir)

      TestServer.stop(pid)

      Process.sleep(100)

      refute File.exists?(tmp_dir)
    end
  end

  describe "path/1" do
    test "returns the path of the workspace"
  end

  describe "delete/1" do

  end

  describe "random_temp_path/1" do
    test "generates a random path in that's in System.tmp!"

    test "generates a random path that's in the given folder"
  end
end
