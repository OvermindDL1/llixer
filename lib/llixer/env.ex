defmodule Llixer.Env do
  @moduledoc """
  Holds the environment and running/compiling state
  """

  alias ExSpirit.TreeMap, as: TreeMap

  defstruct [
    calls: %{},
    read_macros: TreeMap.new(),
    safe: false,
  ]


  def new(opts \\ []) do
    %__MODULE__{
      safe: opts[:safer] || false,
      calls: opts[:mapper] && opts[:mapper].default_calls() || %{},
      read_macros: opts[:mapper] && opts[:mapper].default_read_macros() || TreeMap.new(),
    }
  end



  @doc """
  Takes environment and ast and calls a function and returns an environment and value
  """
  def define_icall(call)
  def define_icall({module, fun, arity, extra_args}=callee) when is_atom(module) and is_atom(fun) and is_integer(arity) and is_list(extra_args), do: {:internal, callee}

  @doc """
  Takes values and calls a function and returns a value
  """
  def define_call(call)
  def define_call({module, fun, arity, extra_args}=callee) when is_atom(module) and is_atom(fun) and is_integer(arity) and is_list(extra_args), do: {:call, callee}

  @doc """
  Takes ast and calls a function and returns an ast
  """
  def define_macro(call)
  def define_macro({module, fun, arity, extra_args}=callee) when is_atom(module) and is_atom(fun) and is_integer(arity) and is_list(extra_args), do: {:macro, callee}

  @doc """
  Returns a value
  """
  def define_value(value), do: {:lit, value}


  def add_icall(%{calls: calls}=env, call, to_be_called) do
    %{env |
      calls: Map.put(calls, call, define_icall(to_be_called)),
    }
  end


  def add_call(%{calls: calls}=env, call, to_be_called) do
    %{env |
      calls: Map.put(calls, call, define_call(to_be_called)),
    }
  end


  def add_macro(%{calls: calls}=env, call, to_be_called) do
    %{env |
      calls: Map.put(calls, call, define_macro(to_be_called)),
    }
  end


  def add_value(%{calls: calls}=env, call, to_be_called) do
    %{env |
      calls: Map.put(calls, call, define_value(to_be_called)),
    }
  end


  def add_external_read_macro(%{read_macros: read_macros}=env, input, {module, fun, args}) when is_atom(module) and is_atom(fun) and is_list(args) do
    if Code.ensure_compiled?(module) and :erlang.function_exported(module, fun, 2+length(args)) do
      %{env |
        read_macros: TreeMap.add(read_macros, input, {module, fun, args}),
      }
    else
      throw :blah
    end
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
