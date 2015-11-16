defmodule TranschangeTest do
  use ExUnit.Case
  doctest Transchange

  alias Transchange.TestRepo

  test "new" do
    assert Transchange.new == %Transchange{}
  end

  test "update changeset" do
    changeset = valid_changeset

    Transchange.new
    |> Transchange.update(:changeset, changeset)
    |> Transchange.run(TestRepo)

    updated = %{changeset | action: :update}
    assert_received {:update, ^updated}
    assert_received {:transaction, _}
  end

  test "insert changeset" do
    changeset = valid_changeset

    Transchange.new
    |> Transchange.insert(:changeset, changeset)
    |> Transchange.run(TestRepo)

    inserted = %{changeset | action: :insert}
    assert_received {:insert, ^inserted}
    assert_received {:transaction, _}
  end

  test "delete changeset" do
    changeset = valid_changeset

    Transchange.new
    |> Transchange.delete(:changeset, changeset)
    |> Transchange.run(TestRepo)

    deleted = %{changeset | action: :delete}
    assert_received {:delete, ^deleted}
    assert_received {:transaction, _}
  end

  test "update invalid changeset" do
    changeset = invalid_changeset

    Transchange.new
    |> Transchange.update(:changeset, changeset)
    |> Transchange.run(TestRepo)

    updated = %{changeset | action: :update}
    refute_received {:update, ^updated}
    refute_received {:transaction, _}
  end

  test "insert invalid changeset" do
    changeset = invalid_changeset

    Transchange.new
    |> Transchange.insert(:changeset, changeset)
    |> Transchange.run(TestRepo)

    inserted = %{changeset | action: :insert}
    refute_received {:insert, ^inserted}
    refute_received {:transaction, _}
  end

  test "delete invalid changeset" do
    changeset = invalid_changeset

    Transchange.new
    |> Transchange.delete(:changeset, changeset)
    |> Transchange.run(TestRepo)

    deleted = %{changeset | action: :delete}
    refute_received {:delete, ^deleted}
    refute_received {:transaction, _}
  end

  test "run with no changesets" do
    Transchange.new
    |> Transchange.run(TestRepo)

    refute_received {:transaction, _}
  end

  defp invalid_changeset, do: %Ecto.Changeset{valid?: false}
  defp valid_changeset,   do: %Ecto.Changeset{valid?: true}
end
