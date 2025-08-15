defmodule FilmvisionWeb.UserLive.Registration do
  use FilmvisionWeb, :live_view

  alias Filmvision.Accounts
  alias Filmvision.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.auth flash={@flash} current_scope={@current_scope}>
      <div class="max-w-lg mx-auto">
        <div class="card">
          <header>
            <h2>Register for an account</h2>
            <p>
              Already registered?
              <.link navigate={~p"/users/log-in"} class="text-blue-600 hover:underline">
                Log in
              </.link>
              to your account now.
            </p>
          </header>
          <section class="grid gap-6">
            <.form
              for={@form}
              id="registration_form"
              phx-submit="save"
              phx-change="validate"
              class="form grid gap-6"
            >
              <div class="grid gap-2">
                <.input
                  field={@form[:email]}
                  type="email"
                  label="Email"
                  autocomplete="username"
                  required
                  phx-mounted={JS.focus()}
                />
              </div>
              <button phx-disable-with="Creating account..." class="btn">
                Create an account
              </button>
            </.form>
          </section>
        </div>
      </div>
    </Layouts.auth>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: FilmvisionWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_email(%User{}, %{}, validate_unique: false)

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{user.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_email(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
