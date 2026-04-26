defmodule Jel.Flavour.Git do
  @behaviour Jel.Flavour

  @impl Jel.Flavour
  def eval_op("git.log", [n_expr], state, eval_fn) do
    n = eval_fn.(n_expr, state) |> trunc()
    git(["log", "--oneline", "-n", to_string(n)])
  end

  def eval_op("git.log", [path_expr, n_expr], state, eval_fn) do
    path = eval_fn.(path_expr, state)
    n    = eval_fn.(n_expr, state) |> trunc()
    git(["log", "--oneline", "-n", to_string(n), "--", path])
  end

  def eval_op("git.diff", [ref_expr], state, eval_fn) do
    ref = eval_fn.(ref_expr, state)
    git(["diff", ref])
  end

  def eval_op("git.diff", [ref1_expr, ref2_expr], state, eval_fn) do
    ref1 = eval_fn.(ref1_expr, state)
    ref2 = eval_fn.(ref2_expr, state)
    git(["diff", ref1, ref2])
  end

  def eval_op("git.blame", [path_expr, line_expr, context_expr], state, eval_fn) do
    path    = eval_fn.(path_expr, state)
    line    = eval_fn.(line_expr, state) |> trunc()
    context = eval_fn.(context_expr, state) |> trunc()
    from    = max(1, line - context)
    to      = line + context
    git(["blame", "-L", "#{from},#{to}", path])
  end

  def eval_op("git.show", [ref_expr], state, eval_fn) do
    ref = eval_fn.(ref_expr, state)
    git(["show", ref])
  end

  def eval_op("git.status", [], _state, _eval_fn) do
    git(["status"])
  end

  def eval_op(_op, _args, _state, _eval_fn), do: :unknown

  defp git(args) do
    case System.cmd("git", args, stderr_to_stdout: true) do
      {output, 0} -> output |> String.trim() |> as_result()
      _           -> nil
    end
  end

  defp as_result(""), do: nil
  defp as_result(str), do: str
end
