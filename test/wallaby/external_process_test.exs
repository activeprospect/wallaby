defmodule Wallaby.ExternalProcessTest do
  use ExUnit.Case, async: true

  alias Wallaby.ExternalProcess

  test "when process starts successfully" do
    cat_path = System.find_executable("cat")

    {:ok, pid} = ExternalProcess.start_link(cat_path)
    os_pid = ExternalProcess.get_os_pid(pid)

    assert_os_process_is_running os_pid
  end

  test "when the process is stopped, shuts down the os process" do
    cat_path = System.find_executable("cat")

    {:ok, pid} = ExternalProcess.start_link(cat_path)
    ref = Process.monitor(pid)
    os_pid = ExternalProcess.get_os_pid(pid)

    :ok = ExternalProcess.stop(pid)

    refute_os_process_is_running os_pid
    assert_receive {:DOWN, ^ref, :process, _, :normal}
  end

  test "when the process is killed, the os process is stopped" do
    Process.flag(:trap_exit, true)
    cat_path = System.find_executable("cat")

    {:ok, pid} = ExternalProcess.start_link(cat_path)
    ref = Process.monitor(pid)
    os_pid = ExternalProcess.get_os_pid(pid)

    Process.exit(pid, :kill)

    refute_os_process_is_running os_pid
    assert_receive {:DOWN, ^ref, :process, _, :killed}
  end

  @tag :capture_log
  test "when the os_process is killed, the process crashes" do
    Process.flag(:trap_exit, true)
    cat_path = System.find_executable("cat")

    {:ok, pid} = ExternalProcess.start_link(cat_path)
    ref = Process.monitor(pid)

    os_pid = ExternalProcess.get_os_pid(pid)
    {_, 0} = System.cmd "kill", [to_string(os_pid)]

    assert_receive {:DOWN, ^ref, :process, _, :crashed}
  end

  test "when unable to start a process" do
    Process.flag(:trap_exit, true)
    path = System.find_executable("doesnotexist")

    assert {:error, :enoent} = ExternalProcess.start_link(path)
  end

  defp assert_os_process_is_running(os_pid) do
    assert os_process_running?(os_pid), """
    process #{os_pid} is running
    """
  end

  defp refute_os_process_is_running(os_pid) do
    refute os_process_running?(os_pid), """
    process #{os_pid} is running
    """
  end

  defp os_process_running?(os_pid) do
    case System.cmd("ps", ["-p", to_string(os_pid)]) do
      {_, 0} -> true
      _ -> false
    end
  end
end
