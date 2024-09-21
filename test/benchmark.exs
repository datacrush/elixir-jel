array_1 = 1..100 |> Enum.to_list()
array_10 = 1..(length(array_1) * 10) |> Enum.to_list()
array_100 = 1..(length(array_10) * 10) |> Enum.to_list()

nested = [%{"-" => array_1} | array_10]

large_data = "
{
  \">\": [
    { \"+\": #{array_100 |> Jason.encode!()} },
    { \"*\": #{nested |> Jason.encode!()} }
  ]
}
"

{:ok, {operator, args}} = Jel.parse_command(large_data)

Benchee.run(
  %{
    "Jel" => fn -> Jel.eval(operator, args) end
  },
  time: 10,
  warmup: 1,
  memory_time: 2
)
