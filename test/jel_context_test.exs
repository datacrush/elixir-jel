defmodule JelContextTest do
  use ExUnit.Case

  test "generates tool schemas for a flavour" do
    tools = Jel.Context.generate(flavours: [Jel.Flavour.Git])
    assert length(tools) > 0

    tool = Enum.find(tools, &(&1.name == "git.log"))
    assert tool.description =~ "git log"
    assert tool.description =~ "Returns:"
    assert tool.description =~ "JEL format:"
    assert tool.input_schema.type == "object"
    assert "n" in tool.input_schema.required
  end

  test "optional params are not in required list" do
    tools = Jel.Context.generate(flavours: [Jel.Flavour.Git])
    tool  = Enum.find(tools, &(&1.name == "git.log"))
    refute "path" in tool.input_schema.required
  end

  test "generates tools for multiple flavours" do
    tools = Jel.Context.generate(flavours: [Jel.Flavour.File, Jel.Flavour.Git])
    names = Enum.map(tools, & &1.name)
    assert "file.grep" in names
    assert "git.blame" in names
  end

  test "returns empty list with no flavours" do
    assert Jel.Context.generate() == []
  end
end
