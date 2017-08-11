defmodule Llixer.SyntaxHelpers do
  @moduledoc """
  Syntax Helpers to be used by Llixer code.

  Currently includes:

  * Read-Macro's
    * Quote, turn \\` into `(quote ...)`
    * Tuple Expressions delinated by `{` and `}` that gets turned in to `(Llixer.SyntaxHelpers.Tuple.lit ...)` calls
    * Map Expressions delinated by `%` that gets turned in to `(Llixer.SyntaxHelpers.Map.lit (..., ...)...)` calls
  """

  def read_macro__quote(context, env) do
    meta = Llixer.Parser.get_meta_from_context(context)
    case Llixer.Parser.parse_expression(context, env) do
      %{error: nil, result: result}=context ->
        %{context |
          result: {:list, meta, [{:name, meta, "quote"}, result]}
        }
      error_context -> error_context
    end
  end

  def read_macro__unquote(context, env) do
    meta = Llixer.Parser.get_meta_from_context(context)
    case Llixer.Parser.parse_expression(context, env) do
      %{error: nil, result: result}=context ->
        %{context |
          result: {:list, meta, [{:name, meta, "unquote"}, result]}
        }
      error_context -> error_context
    end
  end

end
