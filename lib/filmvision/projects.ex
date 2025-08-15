defmodule Filmvision.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false
  alias Filmvision.Repo

  alias Filmvision.Projects.{Project, ProjectMember}
  alias Filmvision.Accounts.{Organization, User}

  def list_projects do
    Repo.all(Project)
  end

  def list_projects_for_organization(%Organization{} = organization) do
    from(p in Project, where: p.organization_id == ^organization.id)
    |> Repo.all()
  end

  def list_projects_for_user(%User{} = user) do
    from(p in Project,
      join: pm in ProjectMember,
      on: pm.project_id == p.id,
      where: pm.user_id == ^user.id,
      distinct: p
    )
    |> Repo.all()
  end

  def get_project!(id), do: Repo.get!(Project, id)

  def get_project(id), do: Repo.get(Project, id)

  def create_project(attrs \\ %{}) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end

  def list_projects_for_member(%User{} = user) do
    query =
      from p in Project,
        join: pm in ProjectMember,
        on: pm.project_id == p.id,
        where: pm.user_id == ^user.id,
        distinct: p

    Repo.all(query)
  end

  def list_all_user_projects(%User{} = user) do
    from(p in Project,
      join: pm in ProjectMember,
      on: pm.project_id == p.id,
      where: pm.user_id == ^user.id,
      distinct: p
    )
    |> Repo.all()
  end

  ## Project Members

  def list_project_members(%Project{} = project) do
    project
    |> Repo.preload(:members)
    |> Map.get(:members)
  end

  def get_project_member(%Project{} = project, %User{} = user) do
    query =
      from pm in ProjectMember,
        where: pm.project_id == ^project.id and pm.user_id == ^user.id

    Repo.one(query)
  end

  def get_user_role_in_project(%User{} = user, %Project{} = project) do
    query =
      from pm in ProjectMember,
        where: pm.user_id == ^user.id and pm.project_id == ^project.id,
        select: pm.role

    Repo.one(query)
  end

  def user_has_project_access?(%User{} = user, %Project{} = project) do
    # User has access if they are a member of the project
    get_user_role_in_project(user, project) != nil
  end

  def add_user_to_project(%User{} = user, %Project{} = project, role \\ "member") do
    %ProjectMember{}
    |> ProjectMember.changeset(%{
      user_id: user.id,
      project_id: project.id,
      role: role
    })
    |> Repo.insert(on_conflict: :nothing)
  end

  def update_user_role_in_project(%User{} = user, %Project{} = project, role) do
    query =
      from pm in ProjectMember,
        where: pm.user_id == ^user.id and pm.project_id == ^project.id

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      project_member ->
        project_member
        |> ProjectMember.changeset(%{role: role})
        |> Repo.update()
    end
  end

  def remove_user_from_project(%User{} = user, %Project{} = project) do
    query =
      from pm in ProjectMember,
        where: pm.user_id == ^user.id and pm.project_id == ^project.id

    Repo.delete_all(query)
  end

  def create_project_with_creator(attrs, %User{} = creator) do
    Repo.transact(fn ->
      with {:ok, project} <- create_project(attrs),
           {:ok, _project_member} <- add_user_to_project(creator, project, "owner") do
        {:ok, project}
      else
        {:error, reason} -> {:error, reason}
      end
    end)
  end

  @doc """
  Gets a project for a specific user and organization.

  Returns the project if the user has access to it, nil otherwise.
  """
  def get_project_for_user_and_organization(
        %User{} = user,
        %Organization{} = organization,
        project_id
      ) do
    query =
      from p in Project,
        join: pm in ProjectMember,
        on: pm.project_id == p.id,
        where: p.id == ^project_id and p.organization_id == ^organization.id and pm.user_id == ^user.id

    Repo.one(query)
  end
end
