defmodule Filmvision.Projects.ProjectMember do
  use Filmvision.Schema
  import Ecto.Changeset

  schema "project_members" do
    field :role, :string, default: "member"

    belongs_to :user, Filmvision.Accounts.User
    belongs_to :project, Filmvision.Projects.Project

    timestamps(type: :utc_datetime)
  end

  def changeset(project_member, attrs) do
    project_member
    |> cast(attrs, [:role, :user_id, :project_id])
    |> validate_required([:role, :user_id, :project_id])
    |> validate_inclusion(:role, ["viewer", "member", "admin", "owner"])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:project_id)
    |> unique_constraint([:user_id, :project_id])
  end
end
