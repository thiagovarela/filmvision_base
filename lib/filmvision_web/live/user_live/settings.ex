defmodule FilmvisionWeb.UserLive.Settings do
  use FilmvisionWeb, :live_view

  on_mount {FilmvisionWeb.UserAuth, :require_sudo_mode}

  alias Filmvision.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-lg mx-auto">
        <div class="card">
          <header>
            <h2>Account Settings</h2>
            <p>Manage your account settings</p>
          </header>
          <section class="grid gap-6">
            <.form
              for={@profile_form}
              id="profile_form"
              phx-submit="update_profile"
              phx-change="validate_profile"
              class="form grid gap-6"
            >
              <div class="grid gap-2">
                <.input
                  field={@profile_form[:name]}
                  type="text"
                  label="Name"
                  placeholder="Your display name"
                />
              </div>
              <div class="grid gap-2">
                <.input
                  field={@profile_form[:image_url]}
                  type="url"
                  label="Profile Image URL"
                  placeholder="https://example.com/your-photo.jpg"
                />
              </div>
              <button phx-disable-with="Updating..." class="btn">Update Profile</button>
            </.form>

            <div class="relative">
              <div class="absolute inset-0 flex items-center">
                <span class="w-full border-t"></span>
              </div>
              <div class="relative flex justify-center text-xs uppercase">
                <span class="bg-card px-2 text-muted-foreground">Email Settings</span>
              </div>
            </div>

            <.form for={@email_form} id="email_form" phx-submit="update_email" phx-change="validate_email" class="form grid gap-6">
              <div class="grid gap-2">
                <.input
                  field={@email_form[:email]}
                  type="email"
                  label="Email"
                  autocomplete="username"
                  required
                />
              </div>
              <button phx-disable-with="Changing..." class="btn">Change Email</button>
            </.form>

            <div class="relative">
              <div class="absolute inset-0 flex items-center">
                <span class="w-full border-t"></span>
              </div>
              <div class="relative flex justify-center text-xs uppercase">
                <span class="bg-card px-2 text-muted-foreground">Password Settings</span>
              </div>
            </div>

            <.form
              for={@password_form}
              id="password_form"
              action={~p"/users/update-password"}
              method="post"
              phx-change="validate_password"
              phx-submit="update_password"
              phx-trigger-action={@trigger_submit}
              class="form grid gap-6"
            >
              <input
                name={@password_form[:email].name}
                type="hidden"
                id="hidden_user_email"
                autocomplete="username"
                value={@current_email}
              />
              <div class="grid gap-2">
                <.input
                  field={@password_form[:password]}
                  type="password"
                  label="New password"
                  autocomplete="new-password"
                  required
                />
              </div>
              <div class="grid gap-2">
                <.input
                  field={@password_form[:password_confirmation]}
                  type="password"
                  label="Confirm new password"
                  autocomplete="new-password"
                />
              </div>
              <button phx-disable-with="Saving..." class="btn">
                Save Password
              </button>
            </.form>
          </section>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email changed successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)
    profile_changeset = Accounts.change_user_profile(user, %{})

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:profile_form, to_form(profile_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_profile", params, socket) do
    %{"user" => user_params} = params

    profile_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, profile_form: profile_form)}
  end

  def handle_event("update_profile", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user

    case Accounts.update_user_profile(user, user_params) do
      {:ok, _user} ->
        info = "Profile updated successfully."
        {:noreply, socket |> put_flash(:info, info)}

      {:error, changeset} ->
        {:noreply, assign(socket, :profile_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end
end
