defmodule StateServer do
  use GenServer

  def start_link(initial_state \\ %{}) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def set(key, value) do
    GenServer.cast(__MODULE__, {:set, key, value})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:reset, new_state}, _state) do
    {:noreply, new_state}
  end

  def handle_cast({:set, key, value}, state) do
    new_state = Map.put(state, key, value)

    {:noreply, new_state}
  end

  def handle_call({:get, key}, _from, state) do
    value = Map.get(state, key)

    {:reply, value, state}
  end
end
