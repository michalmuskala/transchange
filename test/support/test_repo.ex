defmodule Transchange.TestRepo do
  @behaviour Ecto.Repo

  def delete(changeset, _opts) do
    run(:delete, changeset)
  end

  def insert(changeset, _opts) do
    run(:insert, changeset)
  end

  def update(changeset, _opts) do
    run(:update, changeset)
  end

  def transaction(fun, _opts) do
    send(self, {:transaction, fun})
    try do
      {:ok, fun.()}
    catch
      :throw, {:ecto_rollback, value} ->
        {:error, value}
    end
  end

  def rollback(value) do
    throw {:ecto_rollback, value}
  end

  def __adapter__, do: raise "__adapter__"
  def __pool__, do: raise "__pool__"
  def __query_cache__, do: raise "__query_cache__"
  def __repo__, do: raise "__repo__"
  def all(_query, _opts), do: raise "all"
  def config, do: raise "config"
  def delete!(_changeset, _opts), do: raise "delete!"
  def delete_all(_query, _opts), do: raise "delete_all"
  def get(_query, _id, _opts), do: raise "get"
  def get!(_query, _id, _opts), do: raise "get!"
  def get_by(_query, _values, _opts), do: raise "get_by"
  def get_by!(_query, _values, _opts), do: raise "get_by!"
  def insert!(_changeset, _opts), do: raise "insert!"
  def log(_entry), do: raise "log"
  def one(_query, _opts), do: raise "one"
  def one!(_query, _opts), do: raise "one!"
  def preload(_models, _assocs), do: raise "preload"
  def start_link, do: raise "start_link"
  def stop(_pid, _timeout), do: raise "stop"
  def update!(_changeset, _opts), do: raise "update!"
  def update_all(_query, _values, _opts), do: raise "update_all"

  defp run(action, changeset) do
    send(self, {action, changeset})
    if changeset.valid? do
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    else
      {:error, changeset}
    end
  end
end
