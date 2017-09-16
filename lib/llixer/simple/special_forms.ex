defmodule Llixer.Simple.SpecialForms do

  import Llixer.Simple.Evaluator, only: [eval_sexpr: 2, binding_: 1, fun_: 1, fun_: 2]

  def scope, do: %{
    fun_("atom", 1) => {:special_form, __MODULE__, :symbol_to_atom, []},
    fun_("string", 1) => {:special_form, __MODULE__, :symbol_to_string, []},
    fun_("integer", 1) => {:special_form, __MODULE__, :symbol_to_integer, []},
    fun_("float", 1) => {:special_form, __MODULE__, :symbol_to_float, []},
    fun_("atom?", 1) => {:special_form, __MODULE__, :symbol_is_atom, []},
    fun_("string?", 1) => {:special_form, __MODULE__, :symbol_is_string, []},
    fun_("integer?", 1) => {:special_form, __MODULE__, :symbol_is_integer, []},
    fun_("float?", 1) => {:special_form, __MODULE__, :symbol_is_float, []},
  }


  ## Type constructors

  def symbol_to_atom(env, [_cmd, symbol]) when is_binary(symbol) do
    atom =
      if env.safe do
        String.to_existing_atom(symbol)
      else
        String.to_atom(symbol)
      end
    {env, atom}
  end
  def symbol_to_atom(env, [_cmd, atom]) when is_atom(atom), do: {env, atom}
  def symbol_to_atom(env, [cmd, sexpr]) when is_list(sexpr) do
    {env, value} = eval_sexpr(env, sexpr)
    symbol_to_atom(env, [cmd, value])
  end


  ## Type tests

  def symbol_is_atom(env, [_cmd, sexpr]) do
    {env, value} = eval_sexpr(env, sexpr)
    {env, is_atom(value)}
  end

end
