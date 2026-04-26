defmodule JelFlavourGitTest do
  use ExUnit.Case

  @opts [flavours: [Jel.Flavour.Git]]

  test "git.log returns recent commits" do
    {:ok, result} = Jel.eval(~s({"git.log": [5]}), %{}, @opts)
    assert is_binary(result)
  end

  test "git.log scoped to a file" do
    {:ok, result} = Jel.eval(~s({"git.log": ["lib/jel/core.ex", 5]}), %{}, @opts)
    assert is_binary(result) or is_nil(result)
  end

  test "git.show returns commit detail" do
    {:ok, result} = Jel.eval(~s({"git.show": ["HEAD"]}), %{}, @opts)
    assert is_binary(result)
    assert result =~ "commit"
  end

  test "git.diff between two refs" do
    {:ok, result} = Jel.eval(~s({"git.diff": ["HEAD~1", "HEAD"]}), %{}, @opts)
    assert is_binary(result) or is_nil(result)
  end

  test "git.blame returns annotated lines" do
    {:ok, result} = Jel.eval(~s({"git.blame": ["lib/jel/core.ex", 1, 3]}), %{}, @opts)
    assert is_binary(result)
  end
end
