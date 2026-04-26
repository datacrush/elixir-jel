defmodule JelStateTest do
  use ExUnit.Case

  @state %{"first_name" => "John", "last_name" => "Doe", "address" => %{"city" => "NYC"}}

  test "handles flat path lookup" do
    {:ok, result} = Jel.eval(~s({"get": "first_name"}), @state)
    assert result == "John"
  end

  test "handles nested path lookup" do
    {:ok, result} = Jel.eval(~s({"get": "address.city"}), @state)
    assert result == "NYC"
  end

  test "returns nil for missing key" do
    {:ok, result} = Jel.eval(~s({"get": "missing"}), @state)
    assert result == nil
  end

  test "returns nil for missing nested key" do
    {:ok, result} = Jel.eval(~s({"get": "address.zip"}), @state)
    assert result == nil
  end

  test "handles path lookup in expression" do
    {:ok, result} = Jel.eval(~s({"==": [{"get": "first_name"}, "John"]}), @state)
    assert result == true
  end
end
