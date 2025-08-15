defmodule Filmvision.Accounts.Scope do
  @moduledoc """
  Defines the scope of the caller to be used throughout the app.

  The `Filmvision.Accounts.Scope` allows public interfaces to receive
  information about the caller, such as if the call is initiated from an
  end-user, and if so, which user. Additionally, such a scope can carry fields
  such as "super user" or other privileges for use as authorization, or to
  ensure specific code paths can only be access for a given scope.

  It is useful for logging as well as for scoping pubsub subscriptions and
  broadcasts when a caller subscribes to an interface or performs a particular
  action.

  The scope now includes organization and project context, allowing for
  hierarchical access control and resource scoping within the application.

  Feel free to extend the fields on this struct to fit the needs of
  growing application requirements.
  """

  alias Filmvision.Accounts.{User, Organization}
  alias Filmvision.Projects.Project

  defstruct user: nil, organization: nil, project: nil, user_projects: [], current_project_id: nil

  @doc """
  Creates a scope for the given user.

  Returns nil if no user is given.
  """
  def for_user(%User{} = user) do
    %__MODULE__{user: user}
  end

  def for_user(nil), do: nil

  @doc """
  Sets the organization for the given scope.

  Returns the updated scope with the organization set.
  """
  def put_organization(%__MODULE__{} = scope, %Organization{} = organization) do
    %{scope | organization: organization}
  end

  def put_organization(%__MODULE__{} = scope, nil) do
    %{scope | organization: nil}
  end

  @doc """
  Sets the project for the given scope.

  Returns the updated scope with the project set.
  The organization is automatically set from the project if not already present.
  """
  def put_project(%__MODULE__{} = scope, %Project{} = project) do
    scope
    |> put_organization_from_project_if_nil(project)
    |> Map.put(:project, project)
  end

  def put_project(%__MODULE__{} = scope, nil) do
    %{scope | project: nil}
  end

  @doc """
  Creates a scope with user, organization, and project.
  """
  def for_user_organization_project(
        %User{} = user,
        %Organization{} = organization,
        %Project{} = project
      ) do
    %__MODULE__{user: user, organization: organization, project: project}
  end

  def for_user_organization_project(%User{} = user, %Organization{} = organization, nil) do
    %__MODULE__{user: user, organization: organization, project: nil}
  end

  def for_user_organization_project(%User{} = user, nil, nil) do
    %__MODULE__{user: user, organization: nil, project: nil}
  end

  @doc """
  Checks if the scope has access to the given organization.
  """
  def can_access_organization?(
        %__MODULE__{organization: %Organization{id: scope_org_id}},
        %Organization{id: org_id}
      ) do
    scope_org_id == org_id
  end

  def can_access_organization?(%__MODULE__{organization: nil}, _organization), do: false
  def can_access_organization?(nil, _organization), do: false

  @doc """
  Checks if the scope has access to the given project.
  """
  def can_access_project?(%__MODULE__{project: %Project{id: scope_project_id}}, %Project{
        id: project_id
      }) do
    scope_project_id == project_id
  end

  def can_access_project?(%__MODULE__{project: nil}, _project), do: false
  def can_access_project?(nil, _project), do: false

  @doc """
  Sets the user projects for the given scope.

  Returns the updated scope with the user projects set.
  """
  def put_user_projects(%__MODULE__{} = scope, user_projects) when is_list(user_projects) do
    %{scope | user_projects: user_projects}
  end

  @doc """
  Sets the current project ID for the given scope.

  Returns the updated scope with the current project ID set.
  """
  def put_current_project_id(%__MODULE__{} = scope, project_id) do
    %{scope | current_project_id: project_id}
  end

  # Private helper functions

  defp put_organization_from_project_if_nil(
         %__MODULE__{organization: nil} = scope,
         %Project{} = project
       ) do
    case Filmvision.Repo.preload(project, :organization) do
      %Project{organization: %Organization{} = org} -> %{scope | organization: org}
      _ -> scope
    end
  end

  defp put_organization_from_project_if_nil(%__MODULE__{} = scope, _project), do: scope
end
