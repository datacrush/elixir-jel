defmodule JelStateTest do
  use ExUnit.Case

  setup do
    {:ok, pid} = StateServer.start_link(%{"first_name" => "John", "last_name" => "Doe"})
    {:ok, _} = start_supervised({Jel, [&StateServer.get/1, &StateServer.set/2]})

    {:ok, state_server: pid}
  end

  test "handles `get` operator" do
    {:ok, result} = Jel.eval("{ \"get\": [ \"first_name\" ] }")

    assert result == "John"
  end

  test "handles `set` operator" do
    Jel.eval("{ \"set\": [ \"first_name\", \"Jane\" ] }")
    {:ok, result} = Jel.eval("{ \"get\": [ \"first_name\" ] }")

    assert result == "Jane"
  end
end
