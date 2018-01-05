defmodule Runcfg.Mixfile do
  use Mix.Project

  @version "0.0.1"
  @description "Runtime configurations for ephemeral systems"
  @source_url "https://github.com/srevenant/runcfg"

  defp deps() do
    [{:poison, "~> 3.1"}]
  end
end
