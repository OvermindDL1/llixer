defmodule Llixer.Simple.SpecialForms do

  import Llixer.Simple.Evaluator, only: [eval_sexpr: 2, binding_: 1, fun_: 1, fun_: 2]

  alias Llixer.Simple.Env

  def scope, do: %{
    fun_("binding", 1) => {:special_form, __MODULE__, :symbol_to_binding, []},
    fun_("atom", 1) => {:special_form, __MODULE__, :symbol_to_atom, []},
    fun_("string", 1) => {:special_form, __MODULE__, :symbol_to_string, []},
    fun_("integer", 1) => {:special_form, __MODULE__, :symbol_to_integer, []},
    fun_("integer", 2) => {:special_form, __MODULE__, :symbol_to_integer_base, []},
    fun_("float", 1) => {:special_form, __MODULE__, :symbol_to_float, []},
    fun_("atom?", 1) => {:special_form, __MODULE__, :symbol_is_atom, []},
    fun_("string?", 1) => {:special_form, __MODULE__, :symbol_is_string, []},
    fun_("integer?", 1) => {:special_form, __MODULE__, :symbol_is_integer, []},
    fun_("float?", 1) => {:special_form, __MODULE__, :symbol_is_float, []},
  }


  ## Type constructors

  def symbol_to_binding(env, [_cmd, symbol]) when is_binary(symbol), do: {env, Env.get!(env, binding_(symbol))}

  def symbol_to_atom(env, [_cmd, atom]) when is_atom(atom), do: {env, atom}
  def symbol_to_atom(env, [_cmd, symbol]) when is_binary(symbol) do
    atom =
      if env.safe do
        String.to_existing_atom(symbol)
      else
        String.to_atom(symbol)
      end
    {env, atom}
  end
  def symbol_to_atom(env, [cmd, sexpr]) when is_list(sexpr) do
    {env, value} = eval_sexpr(env, sexpr)
    symbol_to_atom(env, [cmd, value])
  end

  def symbol_to_string(env, [_cmd, symbol]) when is_binary(symbol), do: {env, symbol}
  def symbol_to_string(env, [cmd, sexpr]) when is_list(sexpr) do
    {env, value} = eval_sexpr(env, sexpr)
    symbol_to_string(env, [cmd, value])
  end

  def symbol_to_integer(env, [_cmd, integer]) when is_integer(integer), do: {env, integer}
  def symbol_to_integer(env, [_cmd, symbol]) when is_binary(symbol) do
    value = String.to_integer(symbol)
    {env, value}
  end
  def symbol_to_integer(env, [cmd, sexpr]) when is_list(sexpr) do
    {env, value} = eval_sexpr(env, sexpr)
    symbol_to_integer(env, [cmd, value])
  end

  def symbol_to_integer_base(env, [_cmd, integer, _base]) when is_integer(integer), do: {env, integer}
  def symbol_to_integer_base(env, [_cmd, symbol, base]) when is_binary(symbol) do
    base = String.to_integer(base)
    value = String.to_integer(symbol, base)
    {env, value}
  end
  def symbol_to_integer_base(env, [cmd, sexpr, base]) when is_list(sexpr) do
    {env, value} = eval_sexpr(env, sexpr)
    symbol_to_integer_base(env, [cmd, value, base])
  end

  def symbol_to_float(env, [_cmd, float]) when is_float(float), do: {env, float}
  def symbol_to_float(env, [_cmd, symbol]) when is_binary(symbol) do
    value = String.to_float(symbol)
    {env, value}
  end
  def symbol_to_float(env, [cmd, sexpr]) when is_list(sexpr) do
    {env, value} = eval_sexpr(env, sexpr)
    symbol_to_float(env, [cmd, value])
  end


  ## Type tests

  def symbol_is_atom(env, [_cmd, sexpr]) do
    {env, value} = eval_sexpr(env, sexpr)
    {env, is_atom(value)}
  end

  def symbol_is_string(env, [_cmd, sexpr]) do
    {env, value} = eval_sexpr(env, sexpr)
    {env, is_binary(value)}
  end

  def symbol_is_integer(env, [_cmd, sexpr]) do
    {env, value} = eval_sexpr(env, sexpr)
    {env, is_integer(value)}
  end

  def symbol_is_float(env, [_cmd, sexpr]) do
    {env, value} = eval_sexpr(env, sexpr)
    {env, is_float(value)}
  end

end
