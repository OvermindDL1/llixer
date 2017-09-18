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
    cmd_("charlist", 1) => {:special_form, __MODULE__, :symbol_to_charlist, [], %{}},
    cmd_("list") => {:special_form, __MODULE__, :sexpr_to_list, [], %{}},
    cmd_("list-flat") => {:special_form, __MODULE__, :sexpr_to_list_flat, [], %{}},
    cmd_("tuple") => {:special_form, __MODULE__, :sexpr_to_tuple, [], %{}},
    cmd_("quote", 1) => {:macro, __MODULE__, :sexpr_to_quoted, [], %{}},
    cmd_("quasiquote", 1) => {:special_form, __MODULE__, :sexpr_to_quasiquoted, [], %{}},
    cmd_("funcall") => {:special_form, __MODULE__, :funcall, [], %{}},
    cmd_("let") => {:special_form, __MODULE__, :scope_let, [], %{}},

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
  # Handle charlists specially
  def symbol_to_atom(env, [cmd, ["charlist", symbol]]), do: symbol_to_atom(env, [cmd, symbol])
  def symbol_to_atom(env, [cmd, sexpr]) when is_list(sexpr) do
    {env, value} = eval_sexpr(env, sexpr)
    symbol_to_atom(env, [cmd, value])
  end

  def symbol_to_string(env, [_cmd, symbol]) when is_binary(symbol), do: {env, symbol}
  def symbol_to_string(env, [cmd, sexpr]) when is_list(sexpr) do
    {env, value} = eval_sexpr(env, sexpr)
    value = to_string(value)
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

  def symbol_to_charlist(env, [_cmd, symbol]) when is_binary(symbol), do: {env, to_charlist(symbol)}
  def symbol_to_charlist(env, [_cmd, sexpr]) when is_list(sexpr) do
    {env, value} = eval_sexpr(env, sexpr)
    {env, to_charlist(value)}
  end

  def sexpr_to_list(env, [_cmd | list]) do
    Env.map_env(env, list, &eval_sexpr/2)
  end

  def sexpr_to_list_flat(env, [_cmd | list]) do
    Env.flatmap_env(env, list, &eval_sexpr/2)
  end

  def sexpr_to_tuple(env, [_cmd | list]) do
    {env, list} = Env.map_env(env, list, &eval_sexpr/2)
    {env, List.to_tuple(list)}
  end


  ## Primitive calls

  max_arity = 16
  max_args = Enum.map(1..max_arity, fn i -> Macro.var(String.to_atom("$ARG-#{i}"), __MODULE__) end)

  def sexpr_to_quoted(sexpr)
  def sexpr_to_quoted(<<_::binary>> = sexpr), do: ["string", sexpr]
  def sexpr_to_quoted(sexprs), do: ["list" | Enum.map(sexprs, &["quote", &1])]

  def sexpr_to_quasiquoted(sexpr)
  def sexpr_to_quasiquoted(<<_::binary>> = sexpr), do: ["string", sexpr]
  def sexpr_to_quasiquoted(["unquote", sexpr]) do
    sexpr
  end
  def sexpr_to_quasiquoted(sexprs) do
    ["list-flat" | Enum.map(sexprs, fn
      <<_::binary>> = symbol -> ["list", ["string", symbol]]
      ["unquote-splicing", sexpr] -> sexpr
      list -> [["quasiquote", list]]
    end)]
  end

  def sexpr_to_quasiquoted(env, sexpr)
  def sexpr_to_quasiquoted(env, [_cmd, arg]), do: do_sexpr_to_quasiquoted(env, arg)
  def do_sexpr_to_quasiquoted(env, <<_::binary>> = arg), do: {env, arg}
  def do_sexpr_to_quasiquoted(env, []), do: {env, []}
  def do_sexpr_to_quasiquoted(env, ["unquote", arg]) do
    {env, arg} = eval_sexpr(env, arg)
    arg = type_value(arg)
    {env, arg}
  end
  def do_sexpr_to_quasiquoted(env, [_ | _] = args) do
    Env.flatmap_env(env, args, fn
      # env, ["unquote", arg] ->
      #   {env, arg} = eval_sexpr(env, arg) |> throw
      #   arg = type_value(arg)
      #   {env, [arg]}
      env, ["unquote-splicing", args] ->
        {env, args} = eval_sexpr(env, args)
        args = Enum.map(args, &type_value/1)
        {env, args}
      env, <<_::binary>> = symbol -> {env, [symbol]}
      env, list ->
        {env, value} = do_sexpr_to_quasiquoted(env, list)
        {env, [value]}
        # {env, list} = Env.map_env(env, list, &do_sexpr_to_quasiquoted/2)
        # {env, [list]}
    end)
  end

  defp type_value(value)
  defp type_value(<<_::binary>> = value), do: value
  defp type_value([]), do: ["list"]
  defp type_value([_ | _] = values), do: Enum.map(values, &type_value/1)
  defp type_value(value) when is_integer(value), do: ["integer", to_string(value)]
  defp type_value(value) when is_float(value), do: ["float", to_string(value)]
  defp type_value(value) when is_atom(value), do: ["atom", to_string(value)]
  defp type_value(values) when is_tuple(values), do: ["tuple" | Enum.map(Tuple.to_list(values), &type_value/1)]
  defp type_value(value), do: throw {:CANNOT_TYPE_VALUE, value}

  # def sexpr_to_quasiquoted(env, [_cmd, <<_::binary>> = arg]), do: {env, arg}
  # def sexpr_to_quasiquoted(env, [_cmd | [_] = arg_list]) do
  #   {env, [result]} = Env.flatmap_env(env, arg_list, &do_sexpr_to_quasiquoted/2)
  #   {env, result}
  # end
  # defp do_sexpr_to_quasiquoted(env, <<_::binary>> = symbol), do: {env, [symbol]}
  # defp do_sexpr_to_quasiquoted(env, []), do: {env, [[]]}
  # defp do_sexpr_to_quasiquoted(env, ["unquote", arg]) do
  #   {env, result} = eval_sexpr(env, arg)
  #   {env, [result]}
  # end
  # defp do_sexpr_to_quasiquoted(env, ["unquote_splicing", arg]), do: eval_sexpr(env, arg)
  # defp do_sexpr_to_quasiquoted(env, [_ | _] = sexprs) do
  #   {env, result} = Env.flatmap_env(env, sexprs, &do_sexpr_to_quasiquoted/2)
  #   {env, [result]}
  # end

  def funcall(env, [_cmd, fun | args]) do
    {env, fun} = eval_sexpr(env, fun)
    # arity = length(args)
    {env, args} = Env.map_env(env, args, &eval_sexpr/2)
    result = apply(fun, args)
    {env, result}
  end

  @doc """
  This is more like an ML `let` than a LISP `let`, or more like a `let*` with a single body, more powerful overall.
  It is most like an Elixir `for` without the recursion, more functional overall.

  Just keep these in mind:

  * The last value is returned, it must be a simple symbol/call only, like a block
  * A `(name value)` pair where name is a symbol becomes a variable binding
  * Potential expansion later, perhaps destructuring when `name` is not a symbol (currently an error)
  """
  def scope_let(env, [cmd | [_ | _] = sexprs]) do
    env = Env.push_scope(env, cmd)
    {env, result} = do_scope_let(env, sexprs)
    env = Env.pop_scope(env, cmd)
    {env, result}
  end
  defp do_scope_let(env, sexprs)
  defp do_scope_let(env, [body_sexpr]) do
    eval_sexpr(env, body_sexpr)
  end
  defp do_scope_let(env, [[binding_name, binding_sexpr] | [_ | _] = sexprs]) when is_binary(binding_name) do
    {env, arg} = eval_sexpr(env, binding_sexpr)
    env = Env.push(env, binding_(binding_name), arg)
    do_scope_let(env, sexprs)
  end
  defp do_scope_let(env, [[_binding_name, body_sexpr]]) do
    eval_sexpr(env, body_sexpr)
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
  for i <- 0..max_arity do
    args = Enum.take(max_args, i)
    def generate_function(env, unquote(i), args, body) do
      # env = Env.push_scope_blocker(env, :lambda)
      fn(unquote_splicing(args)) ->
        {env, _} =
          Env.zipmap_env(env, args, unquote(args), fn(env, name, value) ->
            {Env.push(env, binding_(name), value), []}
          end)
        {_env, value} = eval_sexpr(env, body)
        value
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
