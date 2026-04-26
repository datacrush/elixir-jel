defmodule JelFlavourFileWriteTest do
  use ExUnit.Case

  @opts [flavours: [Jel.Flavour.File]]

  setup do
    path = Path.join(System.tmp_dir!(), "jel_test_#{:erlang.unique_integer([:positive])}.txt")
    on_exit(fn -> File.rm(path) end)
    {:ok, path: path}
  end

  test "file.write creates a file and returns the path", %{path: path} do
    {:ok, result} = Jel.eval(~s({"file.write": ["#{path}", "hello"]}), %{}, @opts)
    assert result == path
    assert File.read!(path) == "hello"
  end

  test "file.write overwrites existing content", %{path: path} do
    File.write!(path, "original")
    {:ok, _} = Jel.eval(~s({"file.write": ["#{path}", "updated"]}), %{}, @opts)
    assert File.read!(path) == "updated"
  end

  test "file.patch applies a unified diff", %{path: path} do
    File.write!(path, "hello\n")

    diff = """
    --- #{path}
    +++ #{path}
    @@ -1 +1 @@
    -hello
    +world
    """

    state = %{"path" => path, "diff" => diff}

    {:ok, result} = Jel.eval(~s({"file.patch": [{"get": "path"}, {"get": "diff"}]}), state, @opts)
    assert result == path
    assert File.read!(path) == "world\n"
  end

  test "file.patch returns nil on bad diff", %{path: path} do
    File.write!(path, "hello\n")
    {:ok, result} = Jel.eval(~s({"file.patch": ["#{path}", "not a valid diff"]}), %{}, @opts)
    assert result == nil
  end
end
