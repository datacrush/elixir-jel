defmodule JelTest do
  use ExUnit.Case
  doctest Jel

  test "handles `+` operator" do
    {:ok, result} = Jel.eval(~s({"+": [ 2, 3, 4] }))

    assert result == 9
  end

  test "handles `-` operator" do
    {:ok, result} = Jel.eval(~s({"-": [ 2, 3, 4] }))

    assert result == -5
  end

  test "handles `*` operator" do
    {:ok, result} = Jel.eval(~s({"*": [ 2, 3, 4] }))

    assert result == 24
  end

  test "handles the `/` operator" do
    {:ok, result} = Jel.eval(~s({"/": [ 8, 2, 2] }))

    assert result == 2
  end

  test "handles invalid operators" do
    {:error, result} = Jel.eval(~s({"@@": [ 2, 3, 4] }))

    assert result == "invalid operator"
  end
end
