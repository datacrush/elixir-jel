defmodule Jel.Context do
  @moduledoc """
  Generates Anthropic-style tool schemas from registered flavours.
  Pass the result to your LLM as the `tools` parameter.
  """

  def generate(opts \\ []) do
    flavours = Keyword.get(opts, :flavours, [])
    Enum.flat_map(flavours, &to_tools(&1.describe()))
  end

  defp to_tools(specs), do: Enum.map(specs, &to_tool/1)

  defp to_tool(%{op: op, description: description, params: params, returns: returns}) do
    required =
      params
      |> Enum.filter(& &1.required)
      |> Enum.map(& &1.name)

    properties =
      Map.new(params, fn p ->
        {p.name, %{type: p.type, description: p.description}}
      end)

    %{
      name: op,
      description: "#{description}\nReturns: #{returns}\nJEL format: {\"#{op}\": [#{param_hint(params)}]}",
      input_schema: %{
        type: "object",
        properties: properties,
        required: required
      }
    }
  end

  defp param_hint([]), do: ""

  defp param_hint(params) do
    params
    |> Enum.map(fn p -> if p.required, do: "\"#{p.name}\"", else: "\"#{p.name}\"?" end)
    |> Enum.join(", ")
  end
end
