defmodule Jel.Flavour do
  @type param :: %{
          name: String.t(),
          type: String.t(),
          description: String.t(),
          required: boolean()
        }

  @type op_spec :: %{
          op: String.t(),
          description: String.t(),
          params: [param()],
          returns: String.t()
        }

  @callback eval_op(
              op :: String.t(),
              args :: list(),
              state :: term(),
              eval :: (term(), term() -> term())
            ) :: term() | :unknown

  @callback describe() :: [op_spec()]
end
