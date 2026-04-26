defmodule JEL.Core do
  @moduledoc """
  JEL Core v0.3 interpreter (Elixir).

  - Domain-agnostic, host-agnostic semantics
  - Variadic boolean and arithmetic operators
  - Binary comparisons
  - Scalar-only results: boolean | number | String.t() | nil
  - Extensible via flavours
  """

  # ------------------------------------------------------------------
  # 1. Public entry point
  # ------------------------------------------------------------------

  @spec eval(term(), map() | list(), keyword()) :: boolean() | number() | String.t() | nil
  def eval(expr, state, opts \\ []) do
    flavours = Keyword.get(opts, :flavours, [])
    do_eval(expr, state, flavours)
  rescue
    _ -> nil
  end

  # ------------------------------------------------------------------
  # 2. Literal values
  # ------------------------------------------------------------------

  defp do_eval(value, _state, _flavours) when is_boolean(value), do: value
  defp do_eval(value, _state, _flavours) when is_number(value), do: value
  defp do_eval(value, _state, _flavours) when is_binary(value), do: value
  defp do_eval(nil, _state, _flavours), do: nil

  # ------------------------------------------------------------------
  # 3. Path lookup: %{ "get" => "a.b.c" }
  # ------------------------------------------------------------------

  defp do_eval(%{"get" => path}, state, _flavours) when is_binary(path) do
    path
    |> String.split(".")
    |> resolve_path(state)
  end

  # ------------------------------------------------------------------
  # 4. Operator dispatch
  #    %{ "op" => [args...] }
  # ------------------------------------------------------------------

  defp do_eval(map, state, flavours) when is_map(map) do
    case Map.to_list(map) do
      [{op, args}] when is_list(args) ->
        eval_fn = fn e, s -> do_eval(e, s, flavours) end

        case op do
          "&&" -> op_and(args, state, eval_fn)
          "||" -> op_or(args, state, eval_fn)
          "!" -> op_not(args, state, eval_fn)
          "==" -> op_eq(args, state, eval_fn)
          "!=" -> op_neq(args, state, eval_fn)
          ">" -> op_gt(args, state, eval_fn)
          ">=" -> op_gte(args, state, eval_fn)
          "<" -> op_lt(args, state, eval_fn)
          "<=" -> op_lte(args, state, eval_fn)
          "+" -> op_add(args, state, eval_fn)
          "-" -> op_sub(args, state, eval_fn)
          "*" -> op_mul(args, state, eval_fn)
          "/" -> op_div(args, state, eval_fn)
          "%" -> op_mod(args, state, eval_fn)
          "?" -> op_if(args, state, eval_fn)
          _ -> dispatch_flavours(op, args, state, flavours, eval_fn)
        end
    end
  end

  defp do_eval(_other, _state, _flavours), do: nil

  # ------------------------------------------------------------------
  # 5. Flavour chain
  # ------------------------------------------------------------------

  defp dispatch_flavours(_op, _args, _state, [], _eval_fn), do: nil

  defp dispatch_flavours(op, args, state, [flavour | rest], eval_fn) do
    case flavour.eval_op(op, args, state, eval_fn) do
      :unknown -> dispatch_flavours(op, args, state, rest, eval_fn)
      result -> result
    end
  end

  # ================================================================
  # PATH RESOLUTION
  # ================================================================

  defp resolve_path([], _state), do: nil

  defp resolve_path([segment | rest], state) do
    next =
      cond do
        state == nil ->
          nil

        is_list(state) and integer_string?(segment) ->
          idx = String.to_integer(segment)
          if idx >= 0 and idx < length(state), do: Enum.at(state, idx), else: nil

        is_map(state) and Map.has_key?(state, segment) ->
          Map.get(state, segment)

        true ->
          nil
      end

    case rest do
      [] -> next
      _ -> resolve_path(rest, next)
    end
  end

  defp integer_string?(s) when is_binary(s), do: s =~ ~r/^\d+$/

  # ================================================================
  # BOOLEAN OPERATORS (VARIADIC, SHORT-CIRCUIT)
  # ================================================================

  defp op_and(args, state, eval_fn) when is_list(args) do
    case args do
      [] -> true
      _ -> eval_and(args, state, eval_fn)
    end
  end

  defp op_and(_other, _state, _eval_fn), do: nil

  defp eval_and([head | tail], state, eval_fn) do
    if truthy?(eval_fn.(head, state)) do
      eval_and(tail, state, eval_fn)
    else
      false
    end
  end

  defp eval_and([], _state, _eval_fn), do: true

  defp op_or(args, state, eval_fn) when is_list(args) do
    case args do
      [] -> false
      _ -> eval_or(args, state, eval_fn)
    end
  end

  defp op_or(_other, _state, _eval_fn), do: nil

  defp eval_or([head | tail], state, eval_fn) do
    if truthy?(eval_fn.(head, state)) do
      true
    else
      eval_or(tail, state, eval_fn)
    end
  end

  defp eval_or([], _state, _eval_fn), do: false

  defp op_not([expr], state, eval_fn), do: not truthy?(eval_fn.(expr, state))
  defp op_not(_other, _state, _eval_fn), do: nil

  # ================================================================
  # COMPARISON OPERATORS (BINARY ONLY)
  # ================================================================

  defp op_eq([a, b], state, eval_fn) do
    av = eval_fn.(a, state)
    bv = eval_fn.(b, state)

    cond do
      is_number(av) and is_number(bv) -> av == bv
      is_binary(av) and is_binary(bv) -> av == bv
      is_boolean(av) and is_boolean(bv) -> av == bv
      av == nil and bv == nil -> true
      true -> false
    end
  end

  defp op_eq(_other, _state, _eval_fn), do: nil

  defp op_neq(args, state, eval_fn) do
    case op_eq(args, state, eval_fn) do
      nil -> nil
      bool when is_boolean(bool) -> not bool
    end
  end

  defp op_gt([a, b], state, eval_fn), do: compare_numbers(a, b, state, eval_fn, &Kernel.>/2)
  defp op_gt(_other, _state, _eval_fn), do: nil

  defp op_gte([a, b], state, eval_fn), do: compare_numbers(a, b, state, eval_fn, &Kernel.>=/2)
  defp op_gte(_other, _state, _eval_fn), do: nil

  defp op_lt([a, b], state, eval_fn), do: compare_numbers(a, b, state, eval_fn, &Kernel.</2)
  defp op_lt(_other, _state, _eval_fn), do: nil

  defp op_lte([a, b], state, eval_fn), do: compare_numbers(a, b, state, eval_fn, &Kernel.<=/2)
  defp op_lte(_other, _state, _eval_fn), do: nil

  defp compare_numbers(a, b, state, eval_fn, fun) do
    av = eval_fn.(a, state)
    bv = eval_fn.(b, state)

    if is_number(av) and is_number(bv) do
      fun.(av, bv)
    else
      false
    end
  end

  # ================================================================
  # ARITHMETIC OPERATORS (VARIADIC WHERE IT MAKES SENSE)
  # ================================================================

  defp op_add(args, state, eval_fn) when is_list(args) do
    Enum.reduce_while(args, 0, fn expr, acc ->
      case eval_fn.(expr, state) do
        v when is_number(v) -> {:cont, acc + v}
        _ -> {:halt, nil}
      end
    end)
  end

  defp op_add(_other, _state, _eval_fn), do: nil

  defp op_mul(args, state, eval_fn) when is_list(args) do
    Enum.reduce_while(args, 1, fn expr, acc ->
      case eval_fn.(expr, state) do
        v when is_number(v) -> {:cont, acc * v}
        _ -> {:halt, nil}
      end
    end)
  end

  defp op_mul(_other, _state, _eval_fn), do: nil

  defp op_sub([first | rest], state, eval_fn) do
    case eval_fn.(first, state) do
      v when is_number(v) ->
        Enum.reduce_while(rest, v, fn expr, acc ->
          case eval_fn.(expr, state) do
            x when is_number(x) -> {:cont, acc - x}
            _ -> {:halt, nil}
          end
        end)

      _ ->
        nil
    end
  end

  defp op_sub(_other, _state, _eval_fn), do: nil

  defp op_div([first | rest], state, eval_fn) do
    case eval_fn.(first, state) do
      v when is_number(v) ->
        Enum.reduce_while(rest, v, fn expr, acc ->
          case eval_fn.(expr, state) do
            0 -> {:halt, nil}
            x when is_number(x) -> {:cont, acc / x}
            _ -> {:halt, nil}
          end
        end)

      _ ->
        nil
    end
  end

  defp op_div(_other, _state, _eval_fn), do: nil

  defp op_mod([a, b], state, eval_fn) do
    av = eval_fn.(a, state)
    bv = eval_fn.(b, state)

    cond do
      is_number(av) and is_number(bv) and bv != 0 ->
        rem(trunc(av), trunc(bv))

      true ->
        nil
    end
  end

  defp op_mod(_other, _state, _eval_fn), do: nil

  defp op_if([condition, then_expr, else_expr], state, eval_fn) do
    if truthy?(eval_fn.(condition, state)) do
      eval_fn.(then_expr, state)
    else
      eval_fn.(else_expr, state)
    end
  end

  defp op_if(_other, _state, _eval_fn), do: nil

  # ================================================================
  # TRUTHINESS
  # ================================================================

  defp truthy?(value) do
    case value do
      false -> false
      nil -> false
      0 -> false
      "" -> false
      _ -> true
    end
  end
end
