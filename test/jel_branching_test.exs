defmodule JelBranchingTest do
  use ExUnit.Case

  test "takes truthy branch" do
    {:ok, result} = Jel.eval(~s({"?": [{"||": [{">": [3,4]}, {"==": [4,4]}]}, "green", "orange"]}))
    assert result == "green"
  end

  test "takes falsy branch" do
    {:ok, result} = Jel.eval(~s({"?": [{">": [1, 2]}, "green", "orange"]}))
    assert result == "orange"
  end

  test "condition can be a state lookup" do
    {:ok, result} = Jel.eval(~s({"?": [{"get": "active"}, "yes", "no"]}), %{"active" => true})
    assert result == "yes"
  end

  test "wrong arity returns nil" do
    {:ok, result} = Jel.eval(~s({"?": [true, "green"]}))
    assert result == nil
  end
end
