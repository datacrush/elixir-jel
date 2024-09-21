defmodule JelOperatorTest do
  use ExUnit.Case
  doctest Jel

  test "handles `+` operator" do
    {:ok, result} = Jel.eval(~s({"+": [ 2, 3, 4 ] }))

    assert result == 9
  end

  test "handles `-` operator" do
    {:ok, result} = Jel.eval(~s({"-": [ 2, 3, 4 ] }))

    assert result == -5
  end

  test "handles `*` operator" do
    {:ok, result} = Jel.eval(~s({"*": [ 2, 3, 4 ] }))

    assert result == 24
  end

  test "handles the `/` operator" do
    {:ok, result} = Jel.eval(~s({"/": [ 8, 2, 2 ] }))

    assert result == 2
  end

  test "handles `&&` operator false" do
    {:ok, result} = Jel.eval(~s({"&&": [ true, true, false ] }))

    assert result == false
  end

  test "handles `&&` operator true" do
    {:ok, result} = Jel.eval(~s({"&&": [ true, true, true ] }))

    assert result == true
  end

  test "handles `||` operator false" do
    {:ok, result} = Jel.eval(~s({"||": [ false, false, false ] }))

    assert result == false
  end

  test "handles `||` operator true" do
    {:ok, result} = Jel.eval(~s({"||": [ false, false, true ] }))

    assert result == true
  end

  test "handles `==` operator true" do
    {:ok, result} = Jel.eval(~s({"==": [ 2, 2 ] }))

    assert result == true
  end

  test "handles `==` operator false" do
    {:ok, result} = Jel.eval(~s({"==": [ 2, 3 ] }))

    assert result == false
  end

  test "handles `!=` operator true" do
    {:ok, result} = Jel.eval(~s({ "!=": [ 2, 3 ] }))

    assert result == true
  end

  test "handles `!=` operator false" do
    {:ok, result} = Jel.eval(~s({ "!=": [ 2, 2 ] }))

    assert result == false
  end

  test "handles `>` operator false" do
    {:ok, result} = Jel.eval(~s({">": [ 2, 3 ] }))

    assert result == false
  end

  test "handles `>` operator true" do
    {:ok, result} = Jel.eval(~s({">": [ 3, 2 ] }))

    assert result == true
  end

  test "handles `>=` operator false" do
    {:ok, result} = Jel.eval(~s({">=": [ 2, 3 ] }))

    assert result == false
  end

  test "handles `>=` operator true" do
    {:ok, result_gt} = Jel.eval(~s({">=": [ 4, 3 ] }))
    {:ok, result_eq} = Jel.eval(~s({">=": [ 3, 3 ] }))

    assert result_eq == true
    assert result_gt == true
  end

  test "handles `<` operator false" do
    {:ok, result} = Jel.eval(~s({"<": [ 3, 2 ] }))

    assert result == false
  end

  test "handles `<` operator true" do
    {:ok, result} = Jel.eval(~s({"<": [ 2, 3 ] }))

    assert result == true
  end

  test "handles `<=` operator false" do
    {:ok, result} = Jel.eval(~s({"<=": [ 5, 4 ] }))

    assert result == false
  end

  test "handles `<=` operator true" do
    {:ok, result_lt} = Jel.eval(~s({"<=": [ 2, 3 ] }))
    {:ok, result_eq} = Jel.eval(~s({"<=": [ 3, 3 ] }))

    assert result_eq == true
    assert result_lt == true
  end

  test "handles `!` operator" do
    {:ok, result} = Jel.eval(~s({"!": [ true ] }))

    assert result == false
  end

  test "handles `<>` operator" do
    {:ok, result_str} = Jel.eval(~s({"<>": [ "Hello", ", ", "World", "!" ] }))
    {:ok, result_int} = Jel.eval(~s({"<>": [ 1, 2, 3, 4 ] }))

    assert result_int == "1234"
    assert result_str == "Hello, World!"
  end

  test "handles invalid json" do
    {:error, error} = Jel.eval(~s({"!: [ true ] }))

    assert error == "Invalid JSON"
  end

  test "handles invalid operators" do
    {:error, result} = Jel.eval(~s({"@@": [ 2, 3, 4 ] }))

    assert result == "invalid operator"
  end
end
