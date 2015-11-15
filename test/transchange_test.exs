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

    assert_received {:update, %{changeset | action: :update}}
    assert_received {:transaction, _}
  end

  test "insert changeset" do
    changeset = valid_changeset

    Transchange.new
    |> Transchange.insert(:changeset, changeset)
    |> Transchange.run(TestRepo)

    assert_received {:insert, %{changeset | action: :insert}}
    assert_received {:transaction, _}
  end

  test "delete changeset" do
    changeset = valid_changeset

    Transchange.new
    |> Transchange.delete(:changeset, changeset)
    |> Transchange.run(TestRepo)

    assert_received {:delete, %{changeset | action: :delete}}
    assert_received {:transaction, _}
  end

  test "update invalid changeset" do
    changeset = invalid_changeset

    Transchange.new
    |> Transchange.update(:changeset, changeset)
    |> Transchange.run(TestRepo)

    refute_received {:update, ^changeset}
    refute_received {:transaction, _}
  end

  test "insert invalid changeset" do
    changeset = invalid_changeset

    Transchange.new
    |> Transchange.insert(:changeset, changeset)
    |> Transchange.run(TestRepo)

    refute_received {:insert, ^changeset}
    refute_received {:transaction, _}
  end

  test "delete invalid changeset" do
    changeset = invalid_changeset

    Transchange.new
    |> Transchange.delete(:changeset, changeset)
    |> Transchange.run(TestRepo)

    refute_received {:delete, ^changeset}
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
