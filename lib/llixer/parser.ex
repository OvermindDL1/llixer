defmodule Llixer.Parser do
  @moduledoc """
  The parser module also calls back in to the system since in Lisp'y languges they are kind of run at the same time...
  """

  use ExSpirit.Parser, text: true
  #alias ExSpirit.TreeMap
  alias Llixer.Env


  def parse_expression(env, input, opts \\ [])

  def parse_expression(%Env{}=env, input, opts) do
    context = %ExSpirit.Parser.Context{}
    context = %{context |
      skipper:  fn context -> context |> parser_skipper() end,
      rest:     input,
      filename: opts[:filename] || context.filename,
      line:     opts[:line]     || context.line,
      column:   opts[:column]   || context.column,
    }
    parse_expression(context, env, [])
    # parse(input, parser_expression(env) |> skip(), skipper: parser_skipper())
    # case parse(input, parser_expression(env), skipper: parser_skipper()) do
    #   %{error: nil, rest: rest, result: result} -> # There is a read macro defined for here
    #     {result, rest}
    #   context -> context
    # end
  end

  def parse_expression(%ExSpirit.Parser.Context{}=context, %Env{}=env, []) do
    context |> parser_expression(env) |> skip()
  end


  token_separators = [?\s,  ?\n,  ?\r,  ?\t]

  # elixir_operators = # https://hexdocs.pm/elixir/master/operators.html
  #   TreeMap.new()
  #   |> TreeMap.add_text("@", :@)
  #   |> TreeMap.add_text(".", :.)
  #   |> TreeMap.add_text("+", :+)
  #   |> TreeMap.add_text("-", :-)
  #   |> TreeMap.add_text("!", :!)
  #   |> TreeMap.add_text("^", :^)
  #   # |> TreeMap.add_text("not", :not), # Leave out, valid atom anyway
  #   |> TreeMap.add_text("~~~", :~~~)
  #   |> TreeMap.add_text("*", :*)
  #   |> TreeMap.add_text("/", :/)
  #   |> TreeMap.add_text("++", :++)
  #   |> TreeMap.add_text("--", :--)
  #   |> TreeMap.add_text("..", :..)
  #   |> TreeMap.add_text("<>", :<>)
  #   # |> TreeMap.add_text("in", :in), # Leave out, valid atom anyway
  #   # |> TreeMap.add_text("not in", :"not in"), # Leave out, valid atom anyway
  #   |> TreeMap.add_text("|>", :|>)
  #   |> TreeMap.add_text("<<<", :<<<)
  #   |> TreeMap.add_text(">>>", :>>>)
  #   |> TreeMap.add_text("~>>", :~>>)
  #   |> TreeMap.add_text("<<~", :<<~)
  #   |> TreeMap.add_text("~>", :~>)
  #   |> TreeMap.add_text("<~", :<~)
  #   |> TreeMap.add_text("<~>", :<~>)
  #   |> TreeMap.add_text("<|>", :<|>)
  #   |> TreeMap.add_text("<", :<)
  #   |> TreeMap.add_text(">", :>)
  #   |> TreeMap.add_text("<=", :<=)
  #   |> TreeMap.add_text(">=", :>=)
  #   |> TreeMap.add_text("==", :==)
  #   |> TreeMap.add_text("!=", :!=)
  #   |> TreeMap.add_text("=~", :=~)
  #   |> TreeMap.add_text("===", :===)
  #   |> TreeMap.add_text("!==", :!==)
  #   |> TreeMap.add_text("&&", :&&)
  #   |> TreeMap.add_text("&&&", :&&&)
  #   # |> TreeMap.add_text("and", :and), # Leave out, valid atom anyway
  #   |> TreeMap.add_text("||", :||)
  #   |> TreeMap.add_text("|||", :|||)
  #   # |> TreeMap.add_text("or", :or), # Leave out, valid atom anyway
  #   |> TreeMap.add_text("=", :=)
  #   |> TreeMap.add_text("=>", :"=>") # Wtf?  Why is :=> not a valid atom even though all elixir operators with `:` at the front should be valid atoms??
  #   |> TreeMap.add_text("|", :|)
  #   |> TreeMap.add_text("::", :::)
  #   # |> TreeMap.add_text("when", :when), # Leave out, valid atom anyway
  #   |> TreeMap.add_text("<-", :<-)
  #   |> TreeMap.add_text("\\", :\\)
  #   |> TreeMap.add_text("&", :&)


  defrule parser_skipper(chars(unquote(token_separators), 0))

  def get_meta_from_context(context) do
    [line: context.line, column: context.column, position: context.position, filename: context.filename]
  end

  defrule parser_expression_tag(context, tag) do
    %{context |
      result: {tag, get_meta_from_context(context), context.result}
    }
  end

  defrule parser_expression(context, env) do
    context |> alt([
      parser_read_macro(env),
      parser_expression_list(env) |> parser_expression_tag(:cmd),
      # parser_expression_atom(env) |> parser_expression_tag(:atom),
      lit(?-) |> parser_expression_integer(env) |> pipe_result_into(Kernel.-()) |> parser_expression_tag(:integer),
      parser_expression_integer(env) |> parser_expression_tag(:integer),
      parser_expression_float(env) |> parser_expression_tag(:float),
      # parser_expression_quoted_string(env) |> parser_expression_tag(:string),
      parser_expression_name(env) |> parser_expression_tag(:name),
      ])
  end


  defrule parser_expression_list(context, env) do
    context |> seq([
      lit(?(),
      expect(repeat(parser_expression(env))),
      lit(?)),
      ]) |> pipe_result_into(List.wrap())
  end


  defrule parser_expression_name(context, _env) do
    context |> skip()
    |> repeat(no_skip(alt([
        chars([-?), -?\\ | unquote(Enum.map(token_separators, &Kernel.-/1))]),
        lit(?\\) |> alt([
          lit(?n) |> success(?\n),
          lit(?r) |> success(?\r),
          lit(?t) |> success(?\t),
          lit(?s) |> success(?\s),
          char(),
        ]),
      ])), 1)
    |> pipe_result_into(:erlang.iolist_to_binary())
  end


  # defrule parser_expression_quoted_string(context, _env) do
  #   context |> lit(?") |> no_skip(seq([
  #     repeat(nonquote_char_or_escaped_quote(), 1),
  #     lit(?"),
  #   ])) |> pipe_result_into(:erlang.iolist_to_binary())
  # end


  # defrule nonquote_char_or_escaped_quote(alt([
  #   lit(?\\) |> alt([
  #     lit(?n) |> success(?\n),
  #     lit(?r) |> success(?\r),
  #     lit(?t) |> success(?\t),
  #     lit(?s) |> success(?\s),
  #     char(),
  #   ]),
  #   char(-?"),
  # ]))


  # defrule parser_expression_atom_string(alt([
  #   seq([ lit(?"), repeat(nonquote_char_or_escaped_quote(), 1), lit(?")]),
  #   chars1([?A..?Z, ?a..?z, ?_], [?A..?Z, ?a..?z, ?_, ?0..?9, ??, ?!]),
  # ])), pipe_result_into: :erlang.iolist_to_binary()


  # defrule parser_expression_atom(context, env) do
  #   context |> alt([
  #     lit(?:) |> alt([
  #       parser_expression_atom_string() |> parser_expression_atom_to_atom([to_existing: env.safe]),
  #       symbols(unquote(Macro.escape(elixir_operators))),
  #     ]),
  #     # symbols(unquote(Macro.escape(elixir_operators))),
  #     # chars1([?A..?Z, ?_], [?A..?Z, ?a..?z, ?_, ?0..?9, ??, ?!]) |> parser_expression_atom_to_atom([to_existing: env.safe]),
  #   ])
  # end


  defrule parser_expression_atom_to_atom(context, opts \\ []) do
    try do
      atom =
        if opts[:to_existing] do
          String.to_existing_atom(context.result)
        else
          String.to_atom(context.result)
        end
      %{context | result: atom}
    rescue
      ArgumentError ->
        case opts[:else] do
          :return -> context
          _ ->
            %{context |
              error: %ExSpirit.Parser.ParseException{message: "Unable to convert the binary `#{context.result} to an existing atom`", context: context, extradata: context.result},
              result: nil,
            }
        end
    end
  end

  defp helper_parser_integer_branches, do: %{
    ?b => &uint(&1, 2),
    ?o => &uint(&1, 8),
    ?d => &uint(&1, 10),
    ?x => &uint(&1, 16),
  }

  defrule parser_expression_integer(context, _env) do
    context |> skip() |> no_skip(alt([
      seq([ lit(?0) |> branch(char(), helper_parser_integer_branches()) ]),
      uint(),
    ]) |> lookahead_not(char([?., ?e, ?E, ?-])))
  end

  defrule parser_expression_float(context, _env) do
    case Float.parse(context.rest) do
      {float, rest} ->
        %{context |
          result: float,
          rest: rest,
        }
      _ ->
        %{context |
          error: %ExSpirit.Parser.ParseException{message: "Parsing a floating point number failed", context: context},
        }
    end
  end


  defrule parser_read_macro(context,  %{read_macros: read_macros}=env) do
    context |> symbols(read_macros) |> parser_read_macro_exec(env)
  end

  defrule parser_read_macro_exec(context, env) do
    case context.result do
      {module, fun, args} ->
        new_context = apply(module, fun, [context, env]++args)
        case new_context.result do
          input when is_binary(input) -> throw {:TODO, "handle incoming read macro string input"}
          ast when is_tuple(ast) and tuple_size(ast)===3 -> new_context
          invalid -> throw {:READ_MACRO, :INVALID_RETURN, "should be a 3-tuple return of AST", invalid}
        end
    end
  end


end
