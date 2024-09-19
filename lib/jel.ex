defmodule Jel do
  @moduledoc """
  Documentation for `Jel`.
  """

  def eval(json) do
    case Jason.decode(json) do
      {:ok, command} ->
        [{operator, args}] = Map.to_list(command)

        case operator do
          "+" -> {:ok, Enum.sum(args)}
          "-" -> {:ok, Enum.reduce(args, fn x, acc -> acc - x end)}
          "*" -> {:ok, Enum.reduce(args, fn x, acc -> acc * x end)}
          "/" -> {:ok, Enum.reduce(args, fn x, acc -> div(acc, x) end)}
          _ -> {:error, "invalid operator"}
        end

      {:error, error} ->
        {:error, error}
    end
  end
end
