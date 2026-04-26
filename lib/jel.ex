defmodule Jel do
  def eval(json, state \\ %{}, opts \\ []) do
    case Jason.decode(json) do
      {:ok, expr} -> {:ok, Jel.Core.eval(expr, state, opts)}
      {:error, _} -> {:error, :invalid_json}
    end
  end
end
