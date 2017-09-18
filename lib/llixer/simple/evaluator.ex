defmodule Llixer.Simple.Evaluator do

  # import Llixer.Simple.Parser, only: [is_sexpr?: 1]
  alias Llixer.Simple.Env

  def eval_sexpr(env, sexpr)
  def eval_sexpr(env, <<_::binary>> = symbol) do
    value = Env.get!(env, binding_(symbol))
    {env, value}
  end
  def eval_sexpr(env, []), do: {env, []}
  def eval_sexpr(env, [cmd | args] = sexpr) do
    arity = length(args)
    case Env.get(env, cmd_(cmd, arity)) do
      :error -> execute_command(env, -1, Env.get!(env, cmd_(cmd)), sexpr)
      {:ok, call} -> execute_command(env, arity, call, sexpr)
    end
  end


  def execute_command(env, arity, call, sexpr)

  def execute_command(env, _arity, {:special_form, module, fun, args, _meta}, sexpr) do
    apply(module, fun, args ++ [env, sexpr])
  end
  def execute_command(env, -1, {:function, module, fun, args, _meta}, [_cmd | sexpr_args]) do
    {env, sexpr_args} = Env.map_env(env, sexpr_args, &eval_sexpr/2)
    value = apply(module, fun, args ++ [sexpr_args])
    {env, value}
  end
  def execute_command(env, _arity, {:function, module, fun, args, %{force_splice: true} = _meta}, [_cmd | sexpr_args]) do
    {env, sexpr_args} = Env.map_env(env, sexpr_args, &eval_sexpr/2)
    value = apply(module, fun, args ++ [sexpr_args])
    {env, value}
  end
  def execute_command(env, _arity, {:function, module, fun, args, _meta}, [_cmd | sexpr_args]) do
    {env, sexpr_args} = Env.map_env(env, sexpr_args, &eval_sexpr/2)
    value = apply(module, fun, args ++ sexpr_args)
    {env, value}
  end
  def execute_command(env, -1, {:macro, module, fun, args, _meta}, [_cmd | sexpr_args]) do
    sexpr = apply(module, fun, args ++ [sexpr_args])
    eval_sexpr(env, sexpr)
  end
  def execute_command(env, _arity, {:macro, module, fun, args, %{force_splice: true} = _meta}, [_cmd | sexpr_args]) do
    sexpr = apply(module, fun, args ++ [sexpr_args])
    eval_sexpr(env, sexpr)
  end
  def execute_command(env, _arity, {:macro, module, fun, args, _meta}, [_cmd | sexpr_args]) do
    sexpr = apply(module, fun, args ++ sexpr_args)
    eval_sexpr(env, sexpr)
  end

  def execute_command(env, _arity, {:special_form, fun, _meta}, sexpr) when is_function(fun, 2) do
    fun.(env, sexpr)
  end
  def execute_command(env, -1, {:function, fun, _meta}, [_cmd | sexpr_args]) when is_function(fun, 1) do
    {env, sexpr_args} = Env.map_env(env, sexpr_args, &eval_sexpr/2)
    value = fun.(sexpr_args)
    {env, value}
  end
  def execute_command(env, _arity, {:function, fun, %{force_splice: true} = _meta}, [_cmd | sexpr_args]) when is_function(fun, 1) do
    {env, sexpr_args} = Env.map_env(env, sexpr_args, &eval_sexpr/2)
    value = fun.(sexpr_args)
    {env, value}
  end
  def execute_command(env, arity, {:function, fun, _meta}, [_cmd | sexpr_args]) when is_function(fun, arity) do
    {env, sexpr_args} = Env.map_env(env, sexpr_args, &eval_sexpr/2)
    value = apply(fun, sexpr_args)
    {env, value}
  end
  def execute_command(env, -1, {:macro, fun, _meta}, [_cmd | sexpr_args]) when is_function(fun, 1) do
    sexpr = fun.(sexpr_args)
    eval_sexpr(env, sexpr)
  end
  def execute_command(env, _arity, {:macro, fun, %{force_splice: true} = _meta}, [_cmd | sexpr_args]) when is_function(fun, 1) do
    sexpr = fun.(sexpr_args)
    eval_sexpr(env, sexpr)
  end
  def execute_command(env, arity, {:macro, fun, _meta}, [_cmd | sexpr_args]) when is_function(fun, arity) do
    sexpr = apply(fun, sexpr_args)
    eval_sexpr(env, sexpr)
  end


  ## Env helpers

  def binding_(symbol) when is_binary(symbol),                    do: {:binding, symbol}
  def cmd_(cmd)        when is_binary(cmd),                       do: {:fun, cmd}
  def cmd_(cmd, arity) when is_binary(cmd) and is_integer(arity), do: {:fun, cmd, arity}
end
