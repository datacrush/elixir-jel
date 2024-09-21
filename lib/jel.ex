defmodule Jel do
  @moduledoc """
  Documentation for `Jel`.

  See `JelOperatorTest` for an example of a Jel expression.
  """

  def eval(json) do
    case Jason.decode(json) do
      {:ok, command} ->
        [{operator, args}] = Map.to_list(command)

        Jel.eval(operator, args)

      {:error, _} ->
        {:error, "Invalid JSON"}
    end
  end

  def eval(operator, args) do
    dispatch(operator, evaluate_args(args))
  end

  defp dispatch(operator, args) do
    case operator do
      "+" ->
        {:ok, Enum.sum(args)}

      "-" ->
        {:ok, Enum.reduce(args, fn x, acc -> acc - x end)}

      "*" ->
        {:ok, Enum.reduce(args, fn x, acc -> acc * x end)}

      "/" ->
        {:ok, Enum.reduce(args, fn x, acc -> div(acc, x) end)}

      "==" ->
        {:ok, Enum.at(args, 0) == Enum.at(args, 1)}

      "!=" ->
        {:ok, Enum.at(args, 0) != Enum.at(args, 1)}

      "&&" ->
        {:ok, Enum.all?(args, fn x -> x end)}

      "||" ->
        {:ok, Enum.any?(args, fn x -> x end)}

      ">" ->
        {:ok, Enum.at(args, 0) > Enum.at(args, 1)}

      ">=" ->
        {:ok, Enum.at(args, 0) >= Enum.at(args, 1)}

      "<" ->
        {:ok, Enum.at(args, 0) < Enum.at(args, 1)}

      "<=" ->
        {:ok, Enum.at(args, 0) <= Enum.at(args, 1)}

      "!" ->
        {:ok, !Enum.at(args, 0)}

      "<>" ->
        {:ok, Enum.join(args, "")}

      "get" ->
        pid_string = Enum.at(args, 0)
        pid = pid_string |> String.to_charlist() |> :erlang.list_to_pid()
        {:ok, GenServer.call(pid, {:get, Enum.at(args, 1)})}

      "set" ->
        pid_string = Enum.at(args, 0)
        pid = pid_string |> String.to_charlist() |> :erlang.list_to_pid()
        {:ok, GenServer.cast(pid, {:set, Enum.at(args, 1), Enum.at(args, 2)})}

      _ ->
        {:error, "invalid operator"}
    end
  end

  defp evaluate_args(args) do
    Enum.map(args, fn arg ->
      case arg do
        x when is_struct(x) ->
          [{operator, args}] = Map.to_list(x)
          Jel.eval(operator, args)

        _ ->
          arg
      end
    end)
  end
end
