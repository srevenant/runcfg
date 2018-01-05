defmodule Runcfg do
  @moduledoc """
  Follow modern/conventional runtime configuration.

    Runcfg.load(:namespace)

  use in-code as:

    require Runcfg

    Runcfg.get(:token)

  read files in order:

    default.EXT
    {deployment}.EXT
    local.EXT
    local-{deployment}.EXT

  Where EXT can be (in order):

    .yml, .yaml, .json

  """

  import File, only: [ read: 1 ]
  import Application, only: [ get_env: 1, get_env: 2, put_env: 3 ]
  require Poison

  require Logger
  def load(namespace) do
    cfg = Enum.map_reduce(get_file_names(), %{}, fn(file, acc) ->
      Logger.debug(file)
      read_file(file)
      |> process_data(suffix, acc)
    end)
    # todo:
    #  - pull from namespace cfg vars
    #  - pull in OS.env vars (runtime)
    #  - read from stdin (perhaps a diff type of load call)
    Application.put_env(:runcfg, cfg)
  end

  def get_file_names() do
    env =  System.get_env("MIX_ENV") || "dev"
    prefixes = [ "default", env, "local", "local-" <> env ]
    suffixes = ["yml", "json"]

    Enum.reduce(prefixes, [], fn(prefix, acc) ->
      suffixed = Enum.map(suffixes, fn(s) -> "#{prefix}.#{s}" end)
      acc ++ suffixed
    end)
  end

  defp read_file(file) do
    case File.read(path) do
      {:ok, contents} -> contents |> String.trim
      _ -> nil
    end
  end

  defp process_data(nil, _, acc), do: {:ok, acc}
  defp process_data(data, "json", acc) do
    # process json
    left = Poison.Parser.parse!()
    acc = Map.put(acc, :data, deep_merge(Poison.Parser.parse!(data), acc[:data]))
    {:ok, acc}
  end
  defp process_data(data, "yaml", acc), do: process_data(data, "yml", acc)
  defp process_data(data, "yml", acc) do
    # process yaml - not implemented yet
    {:ok, acc}
  end

  def get(name), do: get_env(:runcfg)[name]

  defp read_file(path) do
    case File.read(path) do
      {:ok, contents} -> contents |> String.trim
      _ -> nil
    end
  end

  # borrowed from stackoverflow / asiniy
  # https://stackoverflow.com/questions/38864001/elixir-how-to-deep-merge-maps
  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end
  defp deep_resolve(_key, left = %{}, right = %{}) do
    deep_merge(left, right)
  end
  defp deep_resolve(_key, _left, right) do
    right
  end
end
