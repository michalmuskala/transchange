defmodule Transchange do
  alias Ecto.Changeset

  defstruct changesets: []

  @type name :: atom
  @type pair :: {name, Changeset.t}
  @type model_pair :: {name, Ecto.Model.t}
  @type t :: %__MODULE__{changesets: [pair]}

  @spec new :: t
  def new do
    %Transchange{}
  end

  @spec insert(t, name, Changeset.t) :: t
  def insert(transchange, name, changeset) do
    add_changeset(transchange, :insert, name, changeset)
  end

  @spec update(t, name, Changeset.t) :: t
  def update(transchange, name, changeset) do
    add_changeset(transchange, :update, name, changeset)
  end

  @spec delete(t, name, Changeset.t) :: t
  def delete(transchange, name, changeset) do
    add_changeset(transchange, :delete, name, changeset)
  end

  @spec run(t, Ecto.Repo.t, Keyword.t) :: {:ok, [model_pair]} | {:error, [pair]}
  def run(%Transchange{} = transchange, repo, opts \\ []) when is_atom(repo) do
    transchange.changesets
    |> Enum.reverse
    |> check_changesets_valid
    |> run_transaction(repo, opts)
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
end
