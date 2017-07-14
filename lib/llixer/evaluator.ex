defmodule Llixer.Evaluator do
  @moduledoc """
  Evaluates a Llixer parsed list tree
  """

  alias Llixer.Env
  alias ExSpirit.TreeMap, as: TreeMap



  def default_read_macros(), do: unquote(Macro.escape(
    TreeMap.new()
    |> TreeMap.add("`", {Llixer.SyntaxHelpers, :read_macro__quote, []})
    |> TreeMap.add(",", {Llixer.SyntaxHelpers, :read_macro__unquote, []})
  ))

  def default_calls(), do: %{
    "quote" => Env.define_icall({Llixer.Evaluator.Stdlib, :i__quote, 1, []}),
    "list" => Env.define_icall({Llixer.Evaluator.Stdlib, :i__list, -1, []}),
    "string" => Env.define_icall({Llixer.Evaluator.Stdlib, :i__string, 1, []}),
    "fn" => Env.define_icall({Llixer.Evaluator.Stdlib, :i__fn, -1, []}),
  }

  # Local eval value types:
  # {:call, {module, fun, arity, extra_args}}
  # {:macro, {module, fun, arity, extra_args}}
  # {:lit, value}
  #

  def eval_expression(env, expression)
  def eval_expression(env, {:integer, _meta, i}) when is_integer(i), do: {env, {:lit, i}}
  def eval_expression(env, {:float, _meta, f}) when is_float(f), do: {env, {:lit, f}}
  def eval_expression(%{calls: calls}=env, {:name, meta, name}) do
    # IO.inspect(name, label: :Name)
    case calls[name] do
      nil -> throw "`#{name}` does not exist to be looked up: #{inspect meta}"
      value -> {env, value}
    end
  end
  def eval_expression(env, {:list, _meta, []}), do: {env, []}
  def eval_expression(env, {:list, meta, [ecall | eargs]}) do
    # IO.inspect([ecall | eargs], label: :List)
    case eval_expression(env, ecall) do

      {env, {:internal, {module, fun, arity, extra_args}}} when arity === -1 or arity === length(eargs) ->
        {env=%Env{}, result} =
          if arity === -1 do
            apply(module, fun, [env, eargs | extra_args])
          else
            apply(module, fun, [env | eargs ++ extra_args])
          end
        {env, {:lit, result}}

      {env, {:call, {module, fun, arity, extra_args}}} when arity === -1 or arity === length(eargs) ->
        {env, args} = Env.map_env(env, eargs, &eval_expression/2)
        args = Enum.map(args, &get_raw_value/1)
        if arity === -1 do
          result = apply(module, fun, [args | extra_args])
          {env, {:lit, result}}
        else
          result = apply(module, fun, args ++ extra_args)
          {env, {:lit, result}}
        end

      {env, {:macro, {module, fun, arity, extra_args}}} ->
        expression =
          if arity === -1 do
            apply(module, fun, [eargs | extra_args])
          else
            apply(module, fun, eargs ++ extra_args)
          end
        eval_expression(env, expression)

      {_env, uncallable_value} -> throw "`#{inspect uncallable_value}` is not a callable value from `#{inspect ecall}`: #{inspect meta}"
    end
  end
  def eval_expression(_env, lisp), do:  throw {:UNHANDLED_EVAL_LISP, lisp}


  def get_raw_value(evald_value)
  def get_raw_value({:lit, value}), do: value
  def get_raw_value(evald_value), do: throw {:TODO, :UNHANDLED_GET_RAW_VALUE, evald_value}

end
