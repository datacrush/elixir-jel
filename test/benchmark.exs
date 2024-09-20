med_array = 1..1_000 |> Enum.to_list() |> Jason.encode!()
large_array = 1..10_000 |> Enum.to_list() |> Jason.encode!()

large_data = ~s({">": [ { "+": #{large_array} }, { "*": #{med_array}  } ] })

Benchee.run(
  %{
    "Jel" => fn -> Jel.eval(large_data) end
  },
  time: 10,
  warmup: 1,
  memory_time: 2
)
