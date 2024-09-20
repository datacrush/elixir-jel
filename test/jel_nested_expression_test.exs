defmodule JelExpressionTest do
  use ExUnit.Case
  doctest Jel

  test "handles nested expression" do
    {:ok, result} = Jel.eval(~s({"&&": [ {">": [ 11, 1 ] }, {"<": [ 1, 11 ] } ] }))

    assert result == true
  end
end
