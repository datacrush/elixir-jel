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

  def eval_op("git.branches", [], _state, _eval_fn) do
    git(["branch", "-a"])
  end

  def eval_op("git.checkout", [branch_expr], state, eval_fn) do
    branch = eval_fn.(branch_expr, state)
    git(["checkout", branch])
  end

  def eval_op("git.checkout", [branch_expr, true], state, eval_fn) do
    branch = eval_fn.(branch_expr, state)
    git(["checkout", "-b", branch])
  end

  def eval_op("git.add", [path_expr], state, eval_fn) do
    path = eval_fn.(path_expr, state)
    git(["add", path])
  end

  def eval_op("git.commit", [message_expr], state, eval_fn) do
    message = eval_fn.(message_expr, state)
    git(["commit", "-m", message])
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

  @impl Jel.Flavour
  def describe do
    [
      %{
        op: "git.log",
        description: "Show recent commits (like git log --oneline)",
        params: [
          %{name: "n", type: "number", description: "Number of commits to return", required: true},
          %{name: "path", type: "string", description: "Limit to commits touching this file", required: false}
        ],
        returns: "commit hashes and messages, one per line, or null if no history"
      },
      %{
        op: "git.diff",
        description: "Show changes between refs or between a ref and the working tree (like git diff)",
        params: [
          %{name: "ref1", type: "string", description: "Base ref or commit hash", required: true},
          %{name: "ref2", type: "string", description: "Target ref — omit to diff against working tree", required: false}
        ],
        returns: "unified diff as a string, or null on error"
      },
      %{
        op: "git.blame",
        description: "Show who last modified each line in a range (like git blame -L)",
        params: [
          %{name: "path", type: "string", description: "File path", required: true},
          %{name: "line", type: "number", description: "Target line number", required: true},
          %{name: "context", type: "number", description: "Number of lines before and after", required: true}
        ],
        returns: "annotated lines showing commit hash, author, and content"
      },
      %{
        op: "git.show",
        description: "Show full details of a commit including its diff (like git show)",
        params: [
          %{name: "ref", type: "string", description: "Commit hash or ref e.g. HEAD", required: true}
        ],
        returns: "commit metadata and diff as a string, or null if ref not found"
      },
      %{
        op: "git.status",
        description: "Show the working tree status (like git status)",
        params: [],
        returns: "current branch, staged and unstaged changes as a string"
      },
      %{
        op: "git.branches",
        description: "List all local and remote branches (like git branch -a)",
        params: [],
        returns: "branch names one per line, current branch prefixed with *"
      },
      %{
        op: "git.checkout",
        description: "Switch to a branch, or create and switch to a new one (like git checkout or git checkout -b)",
        params: [
          %{name: "branch", type: "string", description: "Branch name", required: true},
          %{name: "create", type: "boolean", description: "Pass true to create the branch if it does not exist", required: false}
        ],
        returns: "git output on success, or null on failure"
      },
      %{
        op: "git.add",
        description: "Stage a file for commit (like git add)",
        params: [
          %{name: "path", type: "string", description: "File path to stage", required: true}
        ],
        returns: "git output on success, or null on failure"
      },
      %{
        op: "git.commit",
        description: "Commit staged changes with a message (like git commit -m)",
        params: [
          %{name: "message", type: "string", description: "Commit message", required: true}
        ],
        returns: "git output on success, or null on failure"
      }
    ]
  end
end
