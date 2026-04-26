defmodule JelFlavourTest do
  use ExUnit.Case

  defmodule Greet do
    @behaviour Jel.Flavour

    @impl Jel.Flavour
    def eval_op("greet", [name_expr], state, eval_fn) do
      "Hello, #{eval_fn.(name_expr, state)}!"
    end

    def eval_op(_op, _args, _state, _eval_fn), do: :unknown

    @impl Jel.Flavour
    def describe, do: []
  end

  test "flavour operator resolves" do
    {:ok, result} = Jel.eval(~s({"greet": ["world"]}), %{}, flavours: [Greet])
    assert result == "Hello, world!"
  end

  test "flavour operator receives evaluated sub-expression" do
    {:ok, result} = Jel.eval(~s({"greet": [{"get": "name"}]}), %{"name" => "Jane"}, flavours: [Greet])
    assert result == "Hello, Jane!"
  end

  test "unknown operator without flavour returns nil" do
    {:ok, result} = Jel.eval(~s({"greet": ["world"]}))
    assert result == nil
  end
end
