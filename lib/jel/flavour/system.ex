defmodule Jel.Flavour.System do
  @behaviour Jel.Flavour

  @impl Jel.Flavour
  def eval_op("cmd", [cmd | args], state, eval_fn) do
    command = eval_fn.(cmd, state)
    arguments = Enum.map(args, fn arg -> eval_fn.(arg, state) |> to_string() end)

    case System.cmd(command, arguments, stderr_to_stdout: true) do
      {output, 0} -> String.trim(output)
      _ -> nil
    end
  end

  def eval_op(_op, _args, _state, _eval_fn), do: :unknown

  @impl Jel.Flavour
  def describe do
    [
      %{
        op: "cmd",
        description: "Run a system command (like running a command in a terminal)",
        params: [
          %{name: "command", type: "string", description: "The executable to run", required: true},
          %{name: "args", type: "string", description: "Additional arguments, one per array element", required: false}
        ],
        returns: "stdout as a string, or null if the command fails"
      }
    ]
  end
end
