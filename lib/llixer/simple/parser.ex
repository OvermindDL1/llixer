defmodule Llixer.Simple.Parser do
  @moduledoc """
  Primitives necessary are (with renames to fit on the BEAM better or to make the name more sensible):

  * quote = 1-arg, returns it as sexpr (symbol|list(symbol))
  * symbol = 1-arg, base type, anything that is not a list, it is a binary internally
  * eq = 2-arg, compares two sexpr's for deep quality
  * car -> hd = 1-arg, Gets the head of a pair (a proper list is a pair with a pair in the tail or the symbol `nil`)
  * cdr -> tl = 1-arg, Gets the tail of a pair (if a list then returns another pair or the symbol `nil`)
  * cons -> pair = A 2tuple essentially, a basic list element, can also be used to build branching binary trees directly
  * cond = n-arg, A basic comparison switch, BEAM'ized to be like Elixir's `cond` or Erlang's `if`
  * match = n-arg, A basic comparison switch, BEAM'ized to be like Elixir/Erlang's `case`
  * tag = 2-arg, First is a tag of the next structure, second is the structure itself, returns [:tag, &1, &2]
  * type = Returns the first arg of `tag` or built-in name depending on what is passed in
  * rep = Returns the second arg of `tag` or the value straight back if not a tag
  """

  use ExSpirit.Parser, text: true
  alias ExSpirit.Parser.Context
  alias Llixer.Simple.Env


  token_separators = [?\s,  ?\n,  ?\r,  ?\t]


  def parse_expression(env, input, opts \\ [])

  def parse_expression(%Env{}=env, input, opts) do
    context = %ExSpirit.Parser.Context{}
    context = %{context |
      skipper:  fn context -> context |> parser_skipper() end,
      rest:     input,
      filename: opts[:filename] || context.filename,
      line:     opts[:line]     || context.line,
      column:   opts[:column]   || context.column,
      userdata: env,
    }
    parse_expression(context)
  end

  def parse_expression(%ExSpirit.Parser.Context{}=context) do
    context |> parser_expression() |> skip()
  end


  # Validators


  def is_sexpr?(sexpr)
  def is_sexpr?(<<_::binary>>), do: true
  def is_sexpr?([head]), do: is_sexpr?(head)
  def is_sexpr?([head | tail = [_ | _]]), do: is_sexpr?(head) and is_sexpr?(tail)
  def is_sexpr?(_), do: false


  # Parser Grammer


  defrule parser_skipper(chars(unquote(token_separators), 0))


  defrule parser_expression(context) do
    context |> alt([
      parser_read_macro(),
      parser_expression_list(),
      parser_symbol(),
      ])
  end


  defrule parser_read_macro(context) do
    context |> symbols(context.userdata.read_macros) |> expect(parser_read_macro_exec())
  end

  defrule parser_read_macro_exec(context) do
    case context.result do
      {module, fun, args} ->
        case apply(module, fun, [context]++args) do
          %Context{error: nil, result: result} = context ->
            if is_sexpr?(result) do
              context
            else
              %{context|
                result: nil,
                error: %ArgumentError{message: "Invalid Read Macro return of:  #{inspect result}"}
              }
            end
          %Context{} = context -> context
        end
      invalid -> throw {:READ_MACRO, :INVALID_MACRO, invalid}
    end
  end


  defrule parser_expression_list(context) do
    context |> seq([
      lit(?(),
      expect(repeat(parser_expression())),
      lit(?)),
      ]) |> pipe_result_into(List.wrap())
  end


  defrule parser_symbol(context) do
    context |> skip()
    |> repeat(no_skip(alt([
        chars([-?), -?\\ | unquote(Enum.map(token_separators, &Kernel.-/1))]),
        lit(?\\) |> alt([
          lit(?n) |> success(?\n),
          lit(?r) |> success(?\r),
          lit(?t) |> success(?\t),
          lit(?s) |> success(?\s),
          lit(?\n) |> success(?\n),
          lit(?\r) |> success(?\r),
          lit(?\t) |> success(?\t),
          lit(?\s) |> success(?\s),
          char(),
        ]),
      ])), 1)
    |> pipe_result_into(:erlang.iolist_to_binary())
  end
end
