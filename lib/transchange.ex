defmodule Transchange do
  alias Ecto.Changeset

  defstruct changesets: [], ok_pipeline: [], error_pipeline: []

  def new do
    %Transchange{}
  end

  def insert(transchange, name, changeset) do
    add_changeset(transchange, :insert, name, changeset)
  end

  def update(transchange, name, changeset) do
    add_changeset(transchange, :update, name, changeset)
  end

  def delete(transchange, name, changeset) do
    add_changeset(transchange, :delete, name, changeset)
  end

  def pipe_ok(transchange, fun) do
    add_pipeline(transchange, :ok_pipeline, fun)
  end

  def pipe_error(transchange, fun) do
    add_pipeline(transchange, :error_pipeline, fun)
  end

  def run(%Transchange{} = transchange, repo, opts \\ []) when is_atom(repo) do
    transchange.changesets
    |> Enum.reverse
    |> check_changesets_valid
    |> run_transaction(repo, opts)
    |> run_pipeline(transchange)
  end

  defp check_changesets_valid(changesets) do
    invalid? = fn {_, changeset} -> not changeset.valid? end

    case Enum.filter(changesets, invalid?) do
      [] ->
        {:ok, changesets}
      invalid ->
        {:error, invalid}
    end
  end

  defp run_transaction({:ok, []}, _repo, _opts) do
    {:ok, []}
  end

  defp run_transaction({:ok, changesets}, repo, opts) do
    repo.transaction(fn ->
      run_changesets(changesets, repo, opts, [])
    end, opts)
  end

  defp run_transaction({:error, invalid}, _repo, _opts) do
    {:error, invalid}
  end

  defp run_pipeline({:ok, result}, transchange) do
    do_run_pipeline(result, transchange.ok_pipeline)
  end

  defp run_pipeline({:error, result}, transchange) do
    do_run_pipeline(result, transchange.error_pipeline)
  end

  defp do_run_pipeline(result, pipeline) do
    pipeline
    |> Enum.reverse
    |> Enum.reduce(result, fn
      {m, f, a}, result ->
        apply(m, f, [result | a])
      fun, result when is_function(fun) ->
        apply(fun, [result])
    end)
  end

  defp run_changesets([], _repo, _opts, acc) do
    Enum.reverse(acc)
  end

  defp run_changesets([{name, changeset} | rest], repo, opts, acc) do
    case apply(repo, changeset.action, [changeset, opts]) do
      {:ok, model} ->
        run_changesets(rest, repo, opts, [model | acc])
      {:error, changeset} ->
        repo.rollback([{name, changeset}])
    end
  end

  defp add_changeset(%Transchange{} = transchange, action, name, changeset) do
    element = {name, put_action(changeset, action)}
    update_in transchange.changesets, &[element | &1]
  end

  defp add_pipeline(%Transchange{} = transchange, name, fun)
      when is_function(fun, 1) or tuple_size(fun) == 3 do
    Map.update!(transchange, name, &[fun | &1])
  end

  defp put_action(%Changeset{action: nil} = changeset, action) do
    %{changeset | action: action}
  end

  defp put_action(%Changeset{action: action} = changeset, action) do
    changeset
  end

  defp put_action(%Changeset{action: original}, action) do
    raise ArgumentError, "you provided a changeset with an already set action " <>
      "of #{original} when trying to #{action} it"
  end

  defp put_action(_changeset, _action) do
    raise ArgumentError, "Transchange operates only on changesets"
  end

  @doc false
  def reverse_apply(arg, fun) do
    fun.(arg)
  end
end
