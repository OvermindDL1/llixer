defmodule Llixer.Simple.EnvTest do
  use ExUnit.Case
  doctest Llixer.Simple.Env

  alias Llixer.Simple.Env

  test "values" do
    env = Env.new()

    assert {:ok, 42} =
      env
      |> Env.push("test", 42)
      |> Env.get("test")

    assert :error =
      env
      |> Env.push("test", 42)
      |> Env.get("notfound")

    assert {:ok, 42} =
      env
      |> Env.push("test", 42)
      |> Env.get("test")

    assert {:ok, 42} =
      env
      |> Env.push("test", 42)
      |> Env.push_scope(:test)
      |> Env.get("test")

    assert :error =
      env
      |> Env.push("test", 42)
      |> Env.push_scope_blocker(:test)
      |> Env.get("test")
  end

  test "scopes" do
    env = Env.new()

    assert %{scopes: [{_, %{}}]} =
      env
      |> Env.push_scope(:test1)
      |> Env.pop_scope(:test1)

    assert %{scopes: [{:test2, %{}}, {:test1, %{}}, {_, %{}}]} =
      env
      |> Env.push_scope(:test1)
      |> Env.push_scope(:test2)

    assert %{scopes: [{:test1, %{}}, {_, %{}}]} =
      env
      |> Env.push_scope(:test1)
      |> Env.push_scope(:test2)
      |> Env.pop_scope(:test2)

    assert %{scopes: [{_, %{}}]} =
      env
      |> Env.push_scope(:test1)
      |> Env.push_scope(:test2)
      |> Env.pop_scope(:test2)
      |> Env.pop_scope(:test1)

    assert {:ok, 42} =
      env
      |> Env.push_scope(:test1)
      |> Env.push("test", 42)
      |> Env.get("test")

    assert {:ok, 42} =
      env
      |> Env.push_scope(:test1)
      |> Env.push("test", 42)
      |> Env.push_scope(:test2)
      |> Env.get("test")

    assert :error =
      env
      |> Env.push_scope(:test1)
      |> Env.push("test", 42)
      |> Env.push_scope(:test2)
      |> Env.get("wrong")
  end
end
