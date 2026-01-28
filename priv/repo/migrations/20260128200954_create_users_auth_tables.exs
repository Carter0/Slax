defmodule Slax.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    # Some installations of Postgres might not have citext available
    # by default, so before we create the users table we ensure that citext
    # is enabled
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    # citext (case-insensitive text) is a special PostgreSQL
    # column type that lets us store and search text in a case-insensitive manner,
    # which is obviously a good idea for email addresses.
    create table(:users) do
      add :email, :citext, null: false
      add :hashed_password, :string
      add :confirmed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      add :authenticated_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])
  end
end
