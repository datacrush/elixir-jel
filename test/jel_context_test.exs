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

  test "filters operators with only whitelist" do
    tools = Jel.Context.generate(flavours: [{Jel.Flavour.Git, only: ["git.log", "git.status"]}])
    names = Enum.map(tools, & &1.name)
    assert names == ["git.log", "git.status"]
  end

  test "plain module includes all operators" do
    all     = Jel.Context.generate(flavours: [Jel.Flavour.Git])
    filtered = Jel.Context.generate(flavours: [{Jel.Flavour.Git, only: ["git.log"]}])
    assert length(all) > length(filtered)
  end

  test "mixes plain modules and filtered tuples" do
    tools = Jel.Context.generate(flavours: [
      {Jel.Flavour.File, only: ["file.tree"]},
      Jel.Flavour.System
    ])
    names = Enum.map(tools, & &1.name)
    assert "file.tree" in names
    assert "cmd" in names
    refute "file.grep" in names
  end
end
