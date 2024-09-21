array_1 = 1..100 |> Enum.to_list()
array_10 = 1..1_000 |> Enum.to_list()
array_100 = 1..10_000 |> Enum.to_list()

nested = [%{"-" => array_1} | array_10]

large_data = "
{
  \">\": [
    { \"+\": #{array_100 |> Jason.encode!()} },
    { \"*\": #{nested |> Jason.encode!()} }
  ]
}
"

Benchee.run(
  %{
    "Jel" => fn -> Jel.eval(large_data) end
  },
  time: 10,
  warmup: 1,
  memory_time: 2
)
