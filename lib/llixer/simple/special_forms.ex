defmodule Llixer.Simple.SpecialForms do

  import Llixer.Simple.Evaluator, only: [eval_sexpr: 2, binding_: 1, cmd_: 1, cmd_: 2]

  alias Llixer.Simple.Env

  def scope, do: %{
    cmd_("binding", 1) => {:special_form, __MODULE__, :symbol_to_binding, [], %{}},
    cmd_("atom", 1) => {:special_form, __MODULE__, :symbol_to_atom, [], %{}},
    cmd_("string", 1) => {:special_form, __MODULE__, :symbol_to_string, [], %{}},
    cmd_("integer", 1) => {:special_form, __MODULE__, :symbol_to_integer, [], %{}},
    cmd_("integer", 2) => {:special_form, __MODULE__, :symbol_to_integer_base, [], %{}},
    cmd_("float", 1) => {:special_form, __MODULE__, :symbol_to_float, [], %{}},
    cmd_("atom?", 1) => {:special_form, __MODULE__, :symbol_is_atom, [], %{}},
    cmd_("string?", 1) => {:special_form, __MODULE__, :symbol_is_string, [], %{}},
    cmd_("integer?", 1) => {:special_form, __MODULE__, :symbol_is_integer, [], %{}},
    cmd_("float?", 1) => {:special_form, __MODULE__, :symbol_is_float, [], %{}},
    cmd_("lambda", 2) => {:special_form, __MODULE__, :define_lambda, [], %{}},
    cmd_("defun") => {:special_form, __MODULE__, :define_function, [], %{}},
    cmd_("defspecialform") => {:special_form, __MODULE__, :define_specialform, [], %{}},
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


  ## Definitions

  def generate_function(env, arity, head, body)
  def generate_function(env, -1, head, body) do
    generate_function(env, 1, head, body)
  end
  def generate_function(env, 0, [], body) do
    fn ->
      {_env, value} = eval_sexpr(env, body)
      value
    end
  end
  for i <- 0..15 do
    args = Enum.map(1..i, fn i -> String.to_atom("$ARG-#{i}") end)
    def generate_function(env, unquote(i), args, body) do
      env = Env.push_scope_blocker(env, :lambda)
      fn(unquote_splicing(args)) ->
        env =
          Env.zipmap_env(env, args, unquote(args), fn(env, name, value) ->
            Env.push(env, binding_(name), value)
          end)
        :blah
      end
    end
  end

  def wrap_function_call(head, body, args) do
    throw {head, body, args}
  end

  def define_lambda(env, [_cmd, head, body]) do
    {arity, head} =
      case head do
        arg_name when is_binary(arg_name) -> {1, [arg_name]}
        head when is_list(head) -> {length(head), head}
      end
    Enum.each(head, fn
      b when is_binary(b) -> b
      invalid -> throw {:INVALID_FUNC_HEAD, invalid}
    end)
    value = generate_function(env, arity, head, body)
    {env, value}
  end

  def define_function(env, [_cmd, name, head | body], type \\ :function) when is_binary(name) and is_list(head) do
    {cmd, head} =
      case head do
        arg_name when is_binary(arg_name) -> {cmd_(name), [arg_name]}
        head when is_list(head) -> {cmd_(name, length(head)), head}
      end
    Enum.each(head, fn b when is_binary(b) -> b; invalid -> throw {:INVALID_FUNC_HEAD, invalid} end)
    {meta, body} =
      case body do
        [["string", doc] | body] when is_binary(doc) -> {%{force_splice: true, doc: doc}, body}
        _ -> {%{force_splice: true}, body}
      end
    env = Env.push(env, cmd, {type, __MODULE__, :wrap_function_call, [head, body], meta})
    {env, true}
  end

  # def define_specialform(env, [_cmd, name, args, body]) when is_list(args) do
  #   {env, name} = symbol_to_string(env, [:_, name])
  #   arity = length(args)
  #   env = Env.push(env, name, value)
  # end

end
