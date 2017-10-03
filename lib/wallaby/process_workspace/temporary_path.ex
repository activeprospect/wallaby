defmodule Wallaby.ProcessWorkspace.TemporaryPath do
  @moduledoc false

  @spec generate(String.t) :: String.t
  def generate(base_path \\ System.tmp_dir!()) do
    dirname = Integer.to_string(:rand.uniform(0x100000000), 36) |> String.downcase

    Path.join(base_path, dirname)
  end
end
