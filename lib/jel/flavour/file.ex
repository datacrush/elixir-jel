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
end
