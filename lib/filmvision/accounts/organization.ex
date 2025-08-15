defmodule Filmvision.Accounts.Organization do
  use Filmvision.Schema
  import Ecto.Changeset

  schema "organizations" do
    field :name, :string
    field :description, :string

    has_many :user_organizations, Filmvision.Accounts.UserOrganization

    many_to_many :users, Filmvision.Accounts.User,
      join_through: Filmvision.Accounts.UserOrganization

    has_many :projects, Filmvision.Projects.Project

    timestamps(type: :utc_datetime)
  end

  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 255)
  end
end
