defmodule Filmvision.Repo.Migrations.CreateApplicationTables do
  use Ecto.Migration

  def change do
    # Add profile fields to users table
    alter table(:users) do
      add :name, :string
      add :image_url, :string
    end

    # Create organizations table
    create table(:organizations) do
      add :name, :string, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    # Create projects table
    create table(:projects) do
      add :name, :string, null: false
      add :description, :text
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:projects, [:organization_id])

    # Create user_organizations table
    create table(:user_organizations) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false
      add :role, :string, default: "member", null: false

      timestamps(type: :utc_datetime)
    end

    create index(:user_organizations, [:user_id])
    create index(:user_organizations, [:organization_id])
    create unique_index(:user_organizations, [:user_id, :organization_id])

    # Create project_members table
    create table(:project_members) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :role, :string, default: "member", null: false

      timestamps(type: :utc_datetime)
    end

    create index(:project_members, [:user_id])
    create index(:project_members, [:project_id])
    create unique_index(:project_members, [:user_id, :project_id])
  end
end