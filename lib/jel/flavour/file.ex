defmodule Jel.Flavour.File do
  @behaviour Jel.Flavour

  @impl Jel.Flavour
  def eval_op("file.tree", [path_expr], state, eval_fn) do
    path = eval_fn.(path_expr, state)

    case System.cmd("find", [path, "-type", "f"], stderr_to_stdout: true) do
      {output, 0} ->
        output
        |> String.split("\n", trim: true)
        |> Enum.sort()
        |> Enum.join("\n")
        |> as_result()

      _ -> nil
    end
  end

  def eval_op("file.grep", [pattern_expr, path_expr], state, eval_fn) do
    pattern = eval_fn.(pattern_expr, state)
    path    = eval_fn.(path_expr, state)
    grep(["-rn", pattern, path])
  end

  def eval_op("file.grep", [pattern_expr, path_expr, filter_expr], state, eval_fn) do
    pattern = eval_fn.(pattern_expr, state)
    path    = eval_fn.(path_expr, state)
    filter  = eval_fn.(filter_expr, state)
    grep(["-rn", "--include=#{filter}", pattern, path])
  end

  def eval_op("file.context", [path_expr, line_expr, context_expr], state, eval_fn) do
    path    = eval_fn.(path_expr, state)
    line    = eval_fn.(line_expr, state) |> trunc()
    context = eval_fn.(context_expr, state) |> trunc()
    from    = max(1, line - context)
    to      = line + context

    case System.cmd("awk", ["NR>=#{from} && NR<=#{to} {print NR\": \"$0}", path], stderr_to_stdout: true) do
      {output, 0} -> output |> String.trim() |> as_result()
      _           -> nil
    end
  end

  def eval_op("file.head", [path_expr, n_expr], state, eval_fn) do
    path = eval_fn.(path_expr, state)
    n    = eval_fn.(n_expr, state) |> trunc()

    case System.cmd("head", ["-n", to_string(n), path], stderr_to_stdout: true) do
      {output, 0} -> output |> String.trim() |> as_result()
      _           -> nil
    end
  end

  def eval_op("file.write", [path_expr, content_expr], state, eval_fn) do
    path    = eval_fn.(path_expr, state)
    content = eval_fn.(content_expr, state)

    case File.write(path, content) do
      :ok    -> path
      _      -> nil
    end
  end

  def eval_op("file.patch", [path_expr, diff_expr], state, eval_fn) do
    path = eval_fn.(path_expr, state)
    diff = eval_fn.(diff_expr, state)
    tmp  = Path.join(System.tmp_dir!(), "jel_patch_#{:erlang.unique_integer([:positive])}.diff")

    result =
      with :ok <- File.write(tmp, diff),
           {_, 0} <- System.cmd("patch", [path, tmp], stderr_to_stdout: true) do
        path
      else
        _ -> nil
      end

    File.rm(tmp)
    result
  end

  def eval_op(_op, _args, _state, _eval_fn), do: :unknown

  defp grep(args) do
    case System.cmd("grep", args, stderr_to_stdout: true) do
      {output, 0} -> String.trim(output)
      _           -> nil
    end
  end

  defp as_result(""), do: nil
  defp as_result(str), do: str

  @impl Jel.Flavour
  def describe do
    [
      %{
        op: "file.tree",
        description: "List all files under a path (like find path -type f)",
        params: [
          %{name: "path", type: "string", description: "Directory to list", required: true}
        ],
        returns: "newline-separated file paths sorted alphabetically, or null if path not found"
      },
      %{
        op: "file.grep",
        description: "Search for a pattern in files recursively (like grep -rn)",
        params: [
          %{name: "pattern", type: "string", description: "Search pattern", required: true},
          %{name: "path", type: "string", description: "Directory to search", required: true},
          %{name: "filter", type: "string", description: "File extension filter e.g. *.ex", required: false}
        ],
        returns: "matching lines as file:line:content format, or null if no matches"
      },
      %{
        op: "file.context",
        description: "Read lines around a specific line number in a file (like awk NR>=from && NR<=to)",
        params: [
          %{name: "path", type: "string", description: "File path", required: true},
          %{name: "line", type: "number", description: "Target line number", required: true},
          %{name: "context", type: "number", description: "Number of lines to include before and after", required: true}
        ],
        returns: "lines prefixed with line numbers, or null if file not found"
      },
      %{
        op: "file.head",
        description: "Read the first n lines of a file (like head -n)",
        params: [
          %{name: "path", type: "string", description: "File path", required: true},
          %{name: "n", type: "number", description: "Number of lines to return", required: true}
        ],
        returns: "first n lines as a string, or null if file not found"
      },
      %{
        op: "file.write",
        description: "Write content to a file, creating or overwriting it",
        params: [
          %{name: "path", type: "string", description: "File path", required: true},
          %{name: "content", type: "string", description: "Content to write", required: true}
        ],
        returns: "the file path on success, or null on failure"
      },
      %{
        op: "file.patch",
        description: "Apply a unified diff to a file (like patch)",
        params: [
          %{name: "path", type: "string", description: "File path to patch", required: true},
          %{name: "diff", type: "string", description: "Unified diff string", required: true}
        ],
        returns: "the file path on success, or null if the patch fails"
      }
    ]
  end
end
