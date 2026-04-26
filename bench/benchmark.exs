state = %{"user" => %{"score" => 42, "active" => true}}

# Representative expressions matching typical LLM output

simple_arithmetic = %{"+" => [1, 2, 3]}

nested_boolean = %{
  "&&" => [
    %{">" => [%{"get" => "user.score"}, 10]},
    %{"==" => [%{"get" => "user.active"}, true]}
  ]
}

conditional = %{
  "?" => [
    %{">" => [%{"get" => "user.score"}, 100]},
    "high",
    "low"
  ]
}

path_lookup = %{"get" => "user.score"}

nested_boolean_json = Jason.encode!(nested_boolean)

Benchee.run(
  %{
    "simple arithmetic" => fn ->
      Jel.Core.eval(simple_arithmetic, state)
    end,
    "nested boolean"    => fn ->
      Jel.Core.eval(nested_boolean, state)
    end,
    "conditional"       => fn ->
      Jel.Core.eval(conditional, state)
    end,
    "path lookup"       => fn ->
      Jel.Core.eval(path_lookup, state)
    end,
    "full pipeline (nested boolean)" => fn ->
      Jel.eval(nested_boolean_json, state)
    end
  },
  time: 5,
  warmup: 1,
  memory_time: 2
)
