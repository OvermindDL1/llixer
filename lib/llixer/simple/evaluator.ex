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
    case Env.get!(env, fun_(cmd, length(args))) do
      :error -> execute_command(env, Env.get!(env, fun_(cmd)), sexpr)
      call -> execute_command(env, call, sexpr)
    end
  end


  def execute_command(env, call, sexpr)
  def execute_command(env, {:special_form, module, fun, args}, sexpr) do
    apply(module, fun, [env, sexpr | args])
  end


  ## Env helpers

  def binding_(symbol) when is_binary(symbol),                    do: {:binding, symbol}
  def fun_(cmd)        when is_binary(cmd),                       do: {:fun, cmd}
  def fun_(cmd, arity) when is_binary(cmd) and is_integer(arity), do: {:fun, cmd, arity}
end
