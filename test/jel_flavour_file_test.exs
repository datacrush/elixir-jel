defmodule JelFlavourFileTest do
  use ExUnit.Case

  @opts [flavours: [Jel.Flavour.File]]

  test "file.tree lists files in path" do
    {:ok, result} = Jel.eval(~s({"file.tree": ["lib/"]}), %{}, @opts)
    assert result =~ "lib/jel/core.ex"
    assert result =~ "lib/jel/flavour.ex"
  end

  test "file.grep finds matches" do
    {:ok, result} = Jel.eval(~s({"file.grep": ["defmodule", "lib/"]}), %{}, @opts)
    assert result =~ "defmodule"
  end

  test "file.grep with file filter" do
    {:ok, result} = Jel.eval(~s({"file.grep": ["defmodule", "lib/", "*.ex"]}), %{}, @opts)
    assert result =~ "defmodule"
  end

  test "file.grep returns nil when no matches" do
    {:ok, result} = Jel.eval(~s({"file.grep": ["zzznomatch", "lib/"]}), %{}, @opts)
    assert result == nil
  end

  test "file.context returns lines around target with line numbers" do
    {:ok, result} = Jel.eval(~s({"file.context": ["lib/jel/core.ex", 1, 3]}), %{}, @opts)
    assert result =~ "1:"
    assert result =~ "defmodule Jel.Core"
  end

  test "file.context clamps to file bounds" do
    {:ok, result} = Jel.eval(~s({"file.context": ["lib/jel/core.ex", 1, 100]}), %{}, @opts)
    assert result =~ "1:"
    assert is_binary(result)
  end

  test "file.head returns first n lines" do
    {:ok, result} = Jel.eval(~s({"file.head": ["lib/jel/core.ex", 3]}), %{}, @opts)
    assert result =~ "defmodule Jel.Core"
    refute result =~ "def eval"
  end
end
