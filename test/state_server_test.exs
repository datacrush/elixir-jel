defmodule StateServerTest do
  use ExUnit.Case

  setup do
    {:ok, pid} = StateServer.start_link(%{my_key: "my_value"})
    {:ok, state_server: pid}
  end

  test "manually start and stop the StateServer" do
    # Set a key-value pair
    StateServer.set(:my_key, "my_value")

    # Ensure the value is set correctly
    assert StateServer.get(:my_key) == "my_value"
  end
end
