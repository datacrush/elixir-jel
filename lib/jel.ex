defmodule Jel do
  use Agent

  def start_link([getter, setter]) do
    # Agent.start_link(fn -> address end, name: __MODULE__)
    Agent.start_link(fn -> %{getter: getter, setter: setter} end,
      name: __MODULE__
    )
  end

  # Use the custom getter function provided by the user to retrieve state
  def get(key) do
    Agent.get(__MODULE__, fn state -> state.getter.(key) end)
  end

  # Use the custom setter function provided by the user to set state
  def set(key, value) do
    Agent.update(__MODULE__, fn state ->
      state.setter.(key, value)
      state
    end)
  end

  def parse_command(json) do
    case Jason.decode(json) do
      {:ok, command} ->
        {:ok, Map.to_list(command) |> Enum.at(0)}

      {:error, _} ->
        {:error, "Invalid JSON"}
    end
  end

  def eval(json) do
    case parse_command(json) do
      {:ok, {operator, args}} ->
        Jel.eval(operator, args)

      {:error, error} ->
        {:error, error}
    end
  end

  def eval(operator, args) do
    dispatch(operator, evaluate_args(args))
  end

  defp dispatch(operator, args) do
    case Map.fetch(commands(), operator) do
      {:ok, func} ->
        func.(args)

      :error ->
        {:error, "invalid operator"}
    end
  end

  defp evaluate_args(args) do
    Enum.map(args, fn arg ->
      case arg do
        x when is_struct(x) ->
          {operator, args} = Map.to_list(x) |> Enum.at(0)
          eval(operator, args)

        _ ->
          arg
      end
    end)
  end

  defp commands do
    %{
      "+" => fn args -> {:ok, Enum.sum(args)} end,
      "-" => fn args -> {:ok, Enum.reduce(args, fn x, acc -> acc - x end)} end,
      "*" => fn args -> {:ok, Enum.reduce(args, fn x, acc -> acc * x end)} end,
      "/" => fn args -> {:ok, Enum.reduce(args, fn x, acc -> div(acc, x) end)} end,
      "==" => fn [left, right] -> {:ok, left == right} end,
      "!=" => fn [left, right] -> {:ok, left != right} end,
      "&&" => fn args -> {:ok, Enum.all?(args)} end,
      "||" => fn args -> {:ok, Enum.any?(args)} end,
      "!" => fn args -> {:ok, !Enum.at(args, 0)} end,
      ">" => fn [left, right] -> {:ok, left > right} end,
      ">=" => fn [left, right] -> {:ok, left >= right} end,
      "<" => fn [left, right] -> {:ok, left < right} end,
      "<=" => fn [left, right] -> {:ok, left <= right} end,
      "<>" => fn args -> {:ok, Enum.join(args, "")} end,
      "get" => fn [key] ->
        {:ok, get(key)}
      end,
      "set" => fn [key, value] ->
        {:ok, set(key, value)}
      end
    }
  end
end
