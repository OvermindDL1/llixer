defmodule Llixer.Simple.Env do
  @moduledoc """
  Holds the environment and running/compiling state
  """

  alias ExSpirit.TreeMap, as: TreeMap


  defstruct [
    read_macros: TreeMap.new(),
    scopes: [{__MODULE__, %{}}],
    safe: false,
  ]


  def new(opts \\ []) do
    %__MODULE__{
      safe: opts[:safer] || false,
      read_macros: opts[:mapper] && opts[:mapper].default_read_macros() || TreeMap.new(),
    }
  end


  def add_read_macro(%{read_macros: read_macros} = env, input, {module, fun, args}) when is_atom(module) and is_atom(fun) and is_list(args) do
    if Code.ensure_compiled?(module) and :erlang.function_exported(module, fun, 1 + length(args)) do
      %{env |
        read_macros: TreeMap.add(read_macros, input, {module, fun, args}),
      }
    else
      throw :blah
    end
  end


  @doc ~S"""

      iex> env = Llixer.Simple.Env.new()
      iex> Llixer.Simple.Env.push(env, "test", 42).scopes |> hd() |> elem(1)
      %{"test" => 42}


  """
  def push(env, name, value) do
    put_in(env, [Access.key!(:scopes), Access.at(0), Access.elem(1), name], value)
  end

  def get(env, name) do
    Enum.reduce_while(env.scopes, :error, fn
      {_scope_name, %{^name => value}}, _ -> {:halt, {:ok, value}}
      {_scope_name, _scope}, _ -> {:cont, :error}
      _scope_name, _ -> {:halt, :error}
    end)
  end

  def get!(env, name) do
    case get(env, name) do
      {:ok, value} -> value
      :error -> throw {:MISSING_REQUIRED_NAME, name}
    end
  end


  def push_scope(env, id, %{} = scope \\ %{}) do
    %{env|
      scopes: [{id, scope} | env.scopes],
    }
  end

  def push_scope_blocker(env, id) do
    %{env|
      scopes: [id | env.scopes]
    }
  end

  def pop_scope(%{scopes: [{id, _scope} | scopes]} = env, id) do
    %{env|
      scopes: scopes,
    }
  end



  def map_env(env, enumerable, func), do: map_env(env, enumerable, func, [])

  defp map_env(env, [], _func, reversed_results) do
    {env, :lists.reverse(reversed_results)}
  end
  defp map_env(env, [value | rest], func, reversed_results) do
    {env, result} = func.(env, value)
    reversed_results = [result | reversed_results]
    map_env(env, rest, func, reversed_results)
  end


  def zipmap_env(env, enumerableLeft, enumerableRight, func) when length(enumerableLeft) === length(enumerableRight) do
    zipmap_env(env, enumerableLeft, enumerableRight, func, [])
  end

  defp zipmap_env(env, [], [], _func, reversed_results) do
    {env, :lists.reverse(reversed_results)}
  end
  defp zipmap_env(env, [left | restLeft], [right | restRight], func, reversed_results) do
    {env, result} = func.(env, left, right)
    reversed_results = [result | reversed_results]
    zipmap_env(env, restLeft, restRight, func, reversed_results)
  end
end
