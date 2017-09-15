defmodule Llixer.Simple.Evaluator do

  import Llixer.Simple.Parser, only: [is_sexpr?: 1]

  def special_forms do
  end

  def eval_sexpr(env, sexpr)
  def eval_sexpr(env, <<_::binary>> = sexpr), do: throw sexpr
end
