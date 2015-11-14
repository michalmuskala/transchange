defmodule TranschangeTest do
  use ExUnit.Case
  doctest Transchange

  alias Transchange.TestRepo

  test "new" do
    assert Transchange.new == %Transchange{}
  end

  test "pipe_ok with tuple" do
    transchange =
      Transchange.new
      |> Transchange.pipe_ok({__MODULE__, :ok, []})

    assert {__MODULE__, :ok, []} in transchange.ok_pipeline
  end

  test "pipe_ok with fun" do
    fun = &(&1)

    transchange =
      Transchange.new
      |> Transchange.pipe_ok(fun)

    assert fun in transchange.ok_pipeline
  end

  test "pipe_error with tuple" do
    transchange =
      Transchange.new
      |> Transchange.pipe_error({__MODULE__, :error, []})

    assert {__MODULE__, :error, []} in transchange.error_pipeline
  end

  test "pipe_error with fun" do
    fun = &(&1)

    transchange =
      Transchange.new
      |> Transchange.pipe_error(fun)

    assert fun in transchange.error_pipeline
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
