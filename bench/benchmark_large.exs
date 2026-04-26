array_1   = 1..100 |> Enum.to_list()
array_10  = 1..(length(array_1) * 10) |> Enum.to_list()
array_100 = 1..(length(array_10) * 10) |> Enum.to_list()

nested = [%{"-" => array_1} | array_10]

# Pre-decoded expressions — benchmarks the interpreter only
core_expr = %{
  ">" => [
    %{"+" => array_100},
    %{"*" => nested}
  ]
}

# JSON string — benchmarks the full pipeline including Jason.decode
json_expr = Jason.encode!(core_expr)

state = %{}

Benchee.run(
  %{
    "Jel.Core.eval (interpreter only)" => fn ->
      Jel.Core.eval(core_expr, state)
    end,
    "Jel.eval (full pipeline)" => fn ->
      Jel.eval(json_expr, state)
    end
  },
  time: 10,
  warmup: 1,
  memory_time: 2
)
