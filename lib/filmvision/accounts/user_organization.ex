defmodule Filmvision.Accounts.UserOrganization do
  use Filmvision.Schema
  import Ecto.Changeset

  schema "user_organizations" do
    field :role, :string, default: "member"

    belongs_to :user, Filmvision.Accounts.User
    belongs_to :organization, Filmvision.Accounts.Organization

    timestamps(type: :utc_datetime)
  end

  def changeset(user_organization, attrs) do
    user_organization
    |> cast(attrs, [:role, :user_id, :organization_id])
    |> validate_required([:role, :user_id, :organization_id])
    |> validate_inclusion(:role, ["member", "admin", "owner"])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:organization_id)
    |> unique_constraint([:user_id, :organization_id])
  end
end
