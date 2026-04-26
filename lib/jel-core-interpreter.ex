defmodule JEL.Core do
  @moduledoc """
  JEL Core v0.3 interpreter (Elixir).

  - Domain-agnostic, host-agnostic semantics
  - Variadic boolean and arithmetic operators
  - Binary comparisons
  - Scalar-only results: boolean | number | String.t() | nil
  """

  # ------------------------------------------------------------------
  # 1. Public entry point
  # ------------------------------------------------------------------

  @spec eval(term(), map() | list()) :: boolean() | number() | String.t() | nil
  def eval(expr, state) do
    do_eval(expr, state)
  rescue
    _ -> nil
  end

  # ------------------------------------------------------------------
  # 2. Literal values
  # ------------------------------------------------------------------

  defp do_eval(value, _state) when is_boolean(value), do: value
  defp do_eval(value, _state) when is_number(value), do: value
  defp do_eval(value, _state) when is_binary(value), do: value
  defp do_eval(nil, _state), do: nil

  # ------------------------------------------------------------------
  # 3. Path lookup: %{ "get" => "a.b.c" }
  # ------------------------------------------------------------------

  defp do_eval(%{"get" => path}, state) when is_binary(path) do
    path
    |> String.split(".")
    |> resolve_path(state)
  end

  # ------------------------------------------------------------------
  # 4. Operator dispatch
  #    %{ "op" => [args...] }
  # ------------------------------------------------------------------
  defp do_eval(map, state) when is_map(map) do
    case Map.to_list(map) do
      [{op, args}] when is_list(args) ->
        case op do
          # Boolean
          "&&" -> op_and(args, state)
          "||" -> op_or(args, state)
          "!" -> op_not(args, state)
          # Comparison
          "==" -> op_eq(args, state)
          "!=" -> op_neq(args, state)
          ">" -> op_gt(args, state)
          ">=" -> op_gte(args, state)
          "<" -> op_lt(args, state)
          "<=" -> op_lte(args, state)
          # Arithmetic
          "+" -> op_add(args, state)
          "-" -> op_sub(args, state)
          "*" -> op_mul(args, state)
          "/" -> op_div(args, state)
          "%" -> op_mod(args, state)
          _ -> nil
        end
    end
  end

  # Any other shape collapses to null
  defp do_eval(_other, _state), do: nil

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

  # AND: identity = true, variadic
  defp op_and(args, state) when is_list(args) do
    case args do
      [] -> true
      _ -> eval_and(args, state)
    end
  end

  defp op_and(_other, _state), do: nil

  defp eval_and([head | tail], state) do
    if truthy?(do_eval(head, state)) do
      eval_and(tail, state)
    else
      false
    end
  end

  defp eval_and([], _state), do: true

  # OR: identity = false, variadic
  defp op_or(args, state) when is_list(args) do
    case args do
      [] -> false
      _ -> eval_or(args, state)
    end
  end

  defp op_or(_other, _state), do: nil

  defp eval_or([head | tail], state) do
    if truthy?(do_eval(head, state)) do
      true
    else
      eval_or(tail, state)
    end
  end

  defp eval_or([], _state), do: false

  # NOT: unary only
  defp op_not([expr], state), do: not truthy?(do_eval(expr, state))
  defp op_not(_other, _state), do: nil

  # ================================================================
  # COMPARISON OPERATORS (BINARY ONLY)
  # ================================================================

  defp op_eq([a, b], state) do
    av = do_eval(a, state)
    bv = do_eval(b, state)

    cond do
      is_number(av) and is_number(bv) -> av == bv
      is_binary(av) and is_binary(bv) -> av == bv
      is_boolean(av) and is_boolean(bv) -> av == bv
      av == nil and bv == nil -> true
      true -> false
    end
  end

  defp op_eq(_other, _state), do: nil

  defp op_neq(args, state) do
    case op_eq(args, state) do
      nil -> nil
      bool when is_boolean(bool) -> not bool
    end
  end

  # Ordering: numbers only, type mismatch => false
  defp op_gt([a, b], state), do: compare_numbers(a, b, state, &Kernel.>/2)
  defp op_gt(_other, _state), do: nil

  defp op_gte([a, b], state), do: compare_numbers(a, b, state, &Kernel.>=/2)
  defp op_gte(_other, _state), do: nil

  defp op_lt([a, b], state), do: compare_numbers(a, b, state, &Kernel.</2)
  defp op_lt(_other, _state), do: nil

  defp op_lte([a, b], state), do: compare_numbers(a, b, state, &Kernel.<=/2)
  defp op_lte(_other, _state), do: nil

  defp compare_numbers(a, b, state, fun) do
    av = do_eval(a, state)
    bv = do_eval(b, state)

    if is_number(av) and is_number(bv) do
      fun.(av, bv)
    else
      false
    end
  end

  # ================================================================
  # ARITHMETIC OPERATORS (VARIADIC WHERE IT MAKES SENSE)
  # ================================================================

  # + : sum, identity 0
  defp op_add(args, state) when is_list(args) do
    Enum.reduce_while(args, 0, fn expr, acc ->
      case do_eval(expr, state) do
        v when is_number(v) -> {:cont, acc + v}
        _ -> {:halt, nil}
      end
    end)
  end

  defp op_add(_other, _state), do: nil

  # * : product, identity 1
  defp op_mul(args, state) when is_list(args) do
    Enum.reduce_while(args, 1, fn expr, acc ->
      case do_eval(expr, state) do
        v when is_number(v) -> {:cont, acc * v}
        _ -> {:halt, nil}
      end
    end)
  end

  defp op_mul(_other, _state), do: nil

  # - : variadic left-fold, no identity
  defp op_sub([first | rest], state) do
    case do_eval(first, state) do
      v when is_number(v) ->
        Enum.reduce_while(rest, v, fn expr, acc ->
          case do_eval(expr, state) do
            x when is_number(x) -> {:cont, acc - x}
            _ -> {:halt, nil}
          end
        end)

      _ ->
        nil
    end
  end

  defp op_sub(_other, _state), do: nil

  # / : variadic left-fold, no identity, division by zero => nil
  defp op_div([first | rest], state) do
    case do_eval(first, state) do
      v when is_number(v) ->
        Enum.reduce_while(rest, v, fn expr, acc ->
          case do_eval(expr, state) do
            0 -> {:halt, nil}
            x when is_number(x) -> {:cont, acc / x}
            _ -> {:halt, nil}
          end
        end)

      _ ->
        nil
    end
  end

  defp op_div(_other, _state), do: nil

  # % : binary modulo only
  defp op_mod([a, b], state) do
    av = do_eval(a, state)
    bv = do_eval(b, state)

    cond do
      is_number(av) and is_number(bv) and bv != 0 ->
        rem(trunc(av), trunc(bv))

      true ->
        nil
    end
  end

  defp op_mod(_other, _state), do: nil

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
