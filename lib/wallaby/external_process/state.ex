defmodule Wallaby.ExternalProcess.State do
  @moduledoc false

  defstruct [:tmp_dir, :port, wrapper_script: "run_command.sh"]

  @type t :: %__MODULE__{
    tmp_dir: String.t,
    wrapper_script: String.t,
    port: nil | port
  }

  @spec new :: t
  def new do
    %__MODULE__{tmp_dir: gen_tmp_dir()}
  end

  @spec wrapper_script_path(t) :: String.t
  def wrapper_script_path(state) do
    Path.join(state.tmp_dir, state.wrapper_script)
  end

  @spec gen_tmp_dir :: String.t
  defp gen_tmp_dir do
    dirname = Integer.to_string(:rand.uniform(0x100000000), 36) |> String.downcase

    Path.join(System.tmp_dir!, dirname)
  end
end
