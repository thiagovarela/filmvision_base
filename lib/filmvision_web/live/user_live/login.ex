defmodule FilmvisionWeb.UserLive.Login do
  use FilmvisionWeb, :live_view

  alias Filmvision.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.auth flash={@flash} current_scope={@current_scope}>
      <div class="">
        <div class="card w-full">
          <header>
            <h2>Log in</h2>
            <p>Enter your email below to log into your account</p>
            <p>Don't have an account? <.link href={~p"/users/register"}>Sign up</.link></p>
          </header>
          <section class="grid gap-6">
            <div class="flex gap-6">
              <button type="button" class="btn flex-1">
                <svg
                  role="img"
                  fill="currentColor"
                  viewBox="0 0 24 24"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <title>Google</title>
                  <path d="M12.48 10.92v3.28h7.84c-.24 1.84-.853 3.187-1.787 4.133-1.147 1.147-2.933 2.4-6.053 2.4-4.827 0-8.6-3.893-8.6-8.72s3.773-8.72 8.6-8.72c2.6 0 4.507 1.027 5.907 2.347l2.307-2.307C18.747 1.44 16.133 0 12.48 0 5.867 0 .307 5.387.307 12s5.56 12 12.173 12c3.573 0 6.267-1.173 8.373-3.36 2.16-2.16 2.84-5.213 2.84-7.667 0-.76-.053-1.467-.173-2.053H12.48z">
                  </path>
                </svg>
                Google
              </button>
            </div>
            <div class="relative">
              <div class="absolute inset-0 flex items-center">
                <span class="w-full border-t"></span>
              </div>
              <div class="relative flex justify-center text-xs uppercase">
                <span class="bg-card px-2 text-muted-foreground">Or continue with</span>
              </div>
            </div>
            <.form
              :let={f}
              for={@form}
              id="login_form_magic"
              action={~p"/users/log-in"}
              phx-submit="submit_magic"
              class="form grid gap-6"
            >
              <div class="grid gap-2">
                <div class="flex items-center gap-2">
                  <label for="demo-card-form-email">Link via Email</label>
                  <.link
                    :if={local_mail_adapter?()}
                    href="/dev/mailbox"
                    class="ml-auto inline-block md:text-sm text-xs text-muted-foreground underline-offset-4 hover:underline"
                  >
                    To see sent emails, visit the <span class="underline">mailbox page</span>
                  </.link>
                </div>
                <.input
                  readonly={!!@current_scope}
                  field={f[:email]}
                  type="email"
                  label="Email"
                  autocomplete="username"
                  required
                  phx-mounted={JS.focus()}
                />
              </div>
              <button class="btn">Log in</button>
            </.form>
            <div class="relative">
              <div class="absolute inset-0 flex items-center">
                <span class="w-full border-t"></span>
              </div>
              <div class="relative flex justify-center text-xs uppercase">
                <span class="bg-card px-2 text-muted-foreground">Or continue with</span>
              </div>
            </div>
            <.form
              :let={f}
              for={@form}
              id="login_form_password"
              action={~p"/users/log-in"}
              phx-submit="submit_password"
              phx-trigger-action={@trigger_submit}
              class="form grid gap-6"
            >
              <div class="grid gap-2">
                <label for="demo-card-form-email">Email</label>
                <.input
                  readonly={!!@current_scope}
                  field={f[:email]}
                  type="email"
                  label="Email"
                  autocomplete="username"
                  required
                />
              </div>
              <div class="grid gap-2">
                <div class="flex items-center gap-2">
                  <label for="demo-card-form-password">Password</label>
                </div>
                <.input
                  field={@form[:password]}
                  type="password"
                  label="Password"
                  autocomplete="current-password"
                />
              </div>
              <button type="button" class="btn">Log in with email and password</button>
            </.form>
          </section>
        </div>
      </div>
    </Layouts.auth>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:filmvision, Filmvision.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
