defmodule JEL.Flavour do
  @callback eval_op(
              op :: String.t(),
              args :: list(),
              state :: term(),
              eval :: (term(), term() -> term())
            ) :: term() | :unknown
end
