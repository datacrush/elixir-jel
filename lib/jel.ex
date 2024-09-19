defmodule Jel do
  @moduledoc """
  Documentation for `Jel`.
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
    case operator do
      "+" -> {:ok, Enum.sum(args)}
      "-" -> {:ok, Enum.reduce(args, fn x, acc -> acc - x end)}
      "*" -> {:ok, Enum.reduce(args, fn x, acc -> acc * x end)}
      "/" -> {:ok, Enum.reduce(args, fn x, acc -> div(acc, x) end)}
      "==" -> {:ok, Enum.at(args, 0) == Enum.at(args, 1)}
      "!=" -> {:ok, Enum.at(args, 0) != Enum.at(args, 1)}
      "&&" -> {:ok, Enum.all?(args, fn x -> x end)}
      "||" -> {:ok, Enum.any?(args, fn x -> x end)}
      ">" -> {:ok, Enum.at(args, 0) > Enum.at(args, 1)}
      ">=" -> {:ok, Enum.at(args, 0) >= Enum.at(args, 1)}
      "<" -> {:ok, Enum.at(args, 0) < Enum.at(args, 1)}
      "<=" -> {:ok, Enum.at(args, 0) <= Enum.at(args, 1)}
      _ -> {:error, "invalid operator"}
    end
  end
end
