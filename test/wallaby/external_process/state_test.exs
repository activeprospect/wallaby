defmodule Wallaby.ExternalProcess.StateTest do
  use ExUnit.Case, async: true

  alias Wallaby.ExternalProcess.State

  describe "new/0" do
    test "defaults script name to run_command.sh" do
      assert %State{wrapper_script: "run_command.sh"} = State.new
    end

    test "sets a unique tmp dir" do
      state_1 = State.new
      state_2 = State.new

      refute state_1.tmp_dir == state_2.tmp_dir
    end
  end

  describe "wrapper_script_path/1" do
    test "returns path to the wrapper script in the tmp dir" do
      state = State.new

      assert State.wrapper_script_path(state) ==
        Path.join(state.tmp_dir, state.wrapper_script)
    end
  end
end
