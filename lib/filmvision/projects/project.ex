defmodule Filmvision.Projects.Project do
  use Filmvision.Schema
  import Ecto.Changeset

  schema "projects" do
    field :name, :string
    field :description, :string

    belongs_to :organization, Filmvision.Accounts.Organization

    has_many :project_members, Filmvision.Projects.ProjectMember

    many_to_many :members, Filmvision.Accounts.User,
      join_through: Filmvision.Projects.ProjectMember

    timestamps(type: :utc_datetime)
  end

  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :description, :organization_id])
    |> validate_required([:name, :organization_id])
    |> validate_length(:name, min: 1, max: 255)
    |> foreign_key_constraint(:organization_id)
  end
end
