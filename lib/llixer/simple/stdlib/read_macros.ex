defmodule Llixer.Simple.Stdlib.ReadMacros do

  use ExSpirit.Parser, text: true

  alias Llixer.Simple.Env
  alias Llixer.Simple.Parser

  def add_read_macros(env) do
    env
    |> Env.add_read_macro("\"", {__MODULE__, :string_doublequoted, []})
    |> Env.add_read_macro("'", {__MODULE__, :charlist_singlequoted, []})
    |> Env.add_read_macro(":", {__MODULE__, :atom_colon, []})
    |> Env.add_read_macro("[", {__MODULE__, :list_straightbracket, []})
    |> Env.add_read_macro("{", {__MODULE__, :tuple_curlybracket, []})
  end

  def string_doublequoted(context) do
    context
    |> parser_string_doublequoted()
    |> case do
      %{error: nil, result: result} = context when is_binary(result) ->
        %{context |
          result: ["string", result]
        }
      bad_context -> bad_context
    end
  end

  def charlist_singlequoted(context) do
    context
    |> parser_string_singlequoted()
    |> case do
      %{error: nil, result: result} = context when is_binary(result) ->
        %{context |
          result: ["charlist", result]
        }
      bad_context -> bad_context
    end
  end

  def atom_colon(context) do
    case Parser.parse_expression(context) do
      %{error: nil, result: result} = context ->
        %{context |
          result: ["atom", result]
        }
      bad_context -> bad_context
    end
  end

  def list_straightbracket(context) do
    context
    |> seq([
      repeat(alt([
        Parser.parser_read_macro(),
        Parser.parser_expression_list(),
        parser_symbol_straightbracket(),
      ])),
      ignore(Parser.parser_skipper()),
      lit(?])
    ])
    |> case do
      %{error: nil, result: result} = context when is_list(result) ->
        %{context |
          result: ["list" | result]
        }
      bad_context -> bad_context
    end
  end

  def tuple_curlybracket(context) do
    context
    |> seq([
      repeat(alt([
        Parser.parser_read_macro(),
        Parser.parser_expression_list(),
        parser_symbol_curlybracket(),
      ])),
      ignore(Parser.parser_skipper()),
      lit(?})
    ])
    |> case do
      %{error: nil, result: result} = context when is_list(result) ->
        %{context |
          result: ["tuple" | result]
        }
      bad_context -> bad_context
    end
  end

  ## Parsers

  defrule parser_string_doublequoted(context) do
    context |> skip()
    |> seq([
      repeat(no_skip(alt([
        chars([-?", -?\\]),
        lit(?\\) |> alt([
          lit(?") |> success(?"),
          lit(?') |> success(?'),
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
      ]))),
      lit(?"),
    ])
    |> pipe_result_into(:erlang.iolist_to_binary())
  end

  defrule parser_string_singlequoted(context) do
    context |> skip()
    |> seq([
      repeat(no_skip(alt([
        chars([-?', -?\\]),
        lit(?\\) |> alt([
          lit(?") |> success(?"),
          lit(?') |> success(?'),
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
      ]))),
      lit(?'),
    ])
    |> pipe_result_into(:erlang.iolist_to_binary())
  end


  defrule parser_symbol_straightbracket(context) do
    context |> skip()
    |> repeat(no_skip(alt([
        chars([-?(, -?[, -?], -?{, -?\\ | unquote(Enum.map(Parser.get_token_separators, &Kernel.-/1))]),
        lit(?\\) |> alt([
          lit(?() |> success(?(),
          lit(?)) |> success(?)),
          lit(?[) |> success(?[),
          lit(?]) |> success(?]),
          lit(?{) |> success(?{),
          lit(?}) |> success(?}),
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


  defrule parser_symbol_curlybracket(context) do
    context |> skip()
    |> repeat(no_skip(alt([
        chars([-?(, -?[, -?{, -?}, -?\\ | unquote(Enum.map(Parser.get_token_separators, &Kernel.-/1))]),
        lit(?\\) |> alt([
          lit(?() |> success(?(),
          lit(?)) |> success(?)),
          lit(?[) |> success(?[),
          lit(?]) |> success(?]),
          lit(?{) |> success(?{),
          lit(?}) |> success(?}),
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
