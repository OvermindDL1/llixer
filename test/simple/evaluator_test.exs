defmodule Llixer.Simple.EvaluatorTest do
  use ExUnit.Case
  doctest Llixer.Simple.Evaluator

  alias Llixer.Simple.Env
  alias Llixer.Simple.Evaluator

  alias ExSpirit.Parser.ExpectationFailureException

  test "Atoms" do
    env =
      Env.new()

    assert :incomplete = Evaluator.eval_sexpr(env, ["atom", "test"])
  end
end
