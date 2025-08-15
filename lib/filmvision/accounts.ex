defmodule Filmvision.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Filmvision.Repo

  alias Filmvision.Accounts.{User, UserToken, UserNotifier, Organization, UserOrganization}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Checks if a user has any organizations.
  """
  def user_has_organizations?(%User{} = user) do
    user = Repo.preload(user, :organizations)
    length(user.organizations) > 0
  end

  ## User registration

  @doc """
  Registers a user and creates default organization and project.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    Repo.transact(fn ->
      with {:ok, user} <- %User{} |> User.email_changeset(attrs) |> Repo.insert(),
           {:ok, organization} <- create_default_organization_for_user(user),
           {:ok, _project} <- create_default_project_for_user(user, organization) do
        {:ok, user}
      else
        {:error, reason} -> {:error, reason}
      end
    end)
  end

  defp create_default_organization_for_user(%User{} = user) do
    default_name = extract_username_from_email(user.email) <> "'s Organization"

    with {:ok, organization} <-
           create_organization(%{
             name: default_name,
             description: "Default organization for #{user.email}"
           }),
         {:ok, _user_org} <- add_user_to_organization(user, organization, "owner") do
      {:ok, organization}
    end
  end

  defp create_default_project_for_user(%User{} = user, %Organization{} = organization) do
    default_name = "Default"

    alias Filmvision.Projects

    Projects.create_project_with_creator(%{
      name: default_name,
      description: "Default project",
      organization_id: organization.id
    }, user)
  end

  defp extract_username_from_email(email) do
    email
    |> String.split("@")
    |> List.first()
    |> String.capitalize()
  end

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `Filmvision.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `Filmvision.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user profile.

  ## Examples

      iex> change_user_profile(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_profile(user, attrs \\ %{}) do
    User.profile_changeset(user, attrs)
  end

  @doc """
  Updates the user profile.

  ## Examples

      iex> update_user_profile(user, %{name: "John Doe"})
      {:ok, %User{}}

      iex> update_user_profile(user, %{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_profile(user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the user with the given magic link token.
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  There are three cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email and no password is set.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The user has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # Prevent session fixation attacks by disallowing magic links for unconfirmed users with password
      {%User{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        raise """
        magic link log in is not allowed for unconfirmed users with a password set!

        This cannot happen with the default implementation, which indicates that you
        might have adapted the code to a different use case. Please make sure to read the
        "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
        """

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the magic link login instructions to the given user.
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end

  ## Organizations

  def list_organizations do
    Repo.all(Organization)
  end

  def get_organization!(id), do: Repo.get!(Organization, id)

  def get_organization(id), do: Repo.get(Organization, id)

  def create_organization(attrs \\ %{}) do
    %Organization{}
    |> Organization.changeset(attrs)
    |> Repo.insert()
  end

  def update_organization(%Organization{} = organization, attrs) do
    organization
    |> Organization.changeset(attrs)
    |> Repo.update()
  end

  def delete_organization(%Organization{} = organization) do
    Repo.delete(organization)
  end

  def change_organization(%Organization{} = organization, attrs \\ %{}) do
    Organization.changeset(organization, attrs)
  end

  def list_user_organizations(%User{} = user) do
    user
    |> Repo.preload(:organizations)
    |> Map.get(:organizations)
  end

  def get_organization_for_user(%User{} = user, organization_id) do
    query =
      from o in Organization,
        join: uo in UserOrganization,
        on: uo.organization_id == o.id,
        where: uo.user_id == ^user.id and o.id == ^organization_id

    case Repo.one(query) do
      nil -> {:error, :not_found}
      organization -> {:ok, organization}
    end
  end

  def get_user_role_in_organization(%User{} = user, %Organization{} = organization) do
    query =
      from uo in UserOrganization,
        where: uo.user_id == ^user.id and uo.organization_id == ^organization.id,
        select: uo.role

    Repo.one(query)
  end

  def add_user_to_organization(%User{} = user, %Organization{} = organization, role \\ "member") do
    %UserOrganization{}
    |> UserOrganization.changeset(%{
      user_id: user.id,
      organization_id: organization.id,
      role: role
    })
    |> Repo.insert(on_conflict: :nothing)
  end

  def update_user_role_in_organization(%User{} = user, %Organization{} = organization, role) do
    query =
      from uo in UserOrganization,
        where: uo.user_id == ^user.id and uo.organization_id == ^organization.id

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      user_organization ->
        user_organization
        |> UserOrganization.changeset(%{role: role})
        |> Repo.update()
    end
  end

  def remove_user_from_organization(%User{} = user, %Organization{} = organization) do
    query =
      from uo in UserOrganization,
        where: uo.user_id == ^user.id and uo.organization_id == ^organization.id

    Repo.delete_all(query)
  end

  def create_organization_with_user(%User{} = user, attrs) do
    Repo.transact(fn ->
      with {:ok, organization} <- create_organization(attrs),
           {:ok, _user_org} <- add_user_to_organization(user, organization, "owner") do
        {:ok, organization}
      else
        {:error, reason} -> {:error, reason}
      end
    end)
  end
end
