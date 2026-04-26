defmodule Jel.Context do
  @moduledoc """
  Generates Anthropic-style tool schemas from registered flavours.
  Pass the result to your LLM as the `tools` parameter.

  ## Usage

      tools = Jel.Context.generate(flavours: [Jel.Flavour.File, Jel.Flavour.Git])

      # Pass directly to the Anthropic API
      Anthropic.messages(%{
        model: "claude-opus-4-7",
        tools: tools,
        messages: [...]
      })

  ## Adding a flavour

  Implement `Jel.Flavour` and pass it in the list:

      tools = Jel.Context.generate(flavours: [Jel.Flavour.File, MyApp.JEL.Workflow])

  ## Restricting operators

  Pass a `{module, only: [...]}` tuple to expose a subset of a flavour's operators:

      tools = Jel.Context.generate(
        flavours: [
          {Jel.Flavour.File, only: ["file.tree", "file.grep", "file.context", "file.head"]},
          {Jel.Flavour.Git,  only: ["git.log", "git.status"]},
          Jel.Flavour.System
        ]
      )
  """

  def generate(opts \\ []) do
    flavours = Keyword.get(opts, :flavours, [])
    Enum.flat_map(flavours, &flavour_tools/1)
  end

  defp flavour_tools({module, only: whitelist}) do
    module.describe()
    |> Enum.filter(&(&1.op in whitelist))
    |> to_tools()
  end

  defp flavour_tools(module), do: to_tools(module.describe())

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
