defmodule JelStateTest do
  use ExUnit.Case

  setup do
    {:ok, pid} = StateServer.start_link(%{"first_name" => "John", "last_name" => "Doe"})

    {:ok, state_server: pid}
  end

  test "handles `get` operator", %{state_server: pid} do
    pid_as_list = :erlang.pid_to_list(pid)

    {:ok, result} = Jel.eval("{\"get\": [ \"#{pid_as_list}\", \"first_name\" ] }")

    assert result == "John"
  end

  test "handles `set` operator", %{state_server: pid} do
    pid_as_list = :erlang.pid_to_list(pid)

    Jel.eval("{ \"set\": [ \"#{pid_as_list}\", \"first_name\", \"Jane\" ] }")

    new_first_name = GenServer.call(pid, {:get, "first_name"})

    assert new_first_name == "Jane"
  end
end
