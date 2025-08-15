defmodule FilmvisionWeb.OnboardingLive do
  use FilmvisionWeb, :live_view

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    {:ok,
     socket
     |> assign(:current_user, user)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="card w-full @md:w-auto @md:min-w-sm">
        <header>
          <div class="bg-accent animate-pulse rounded-md h-4 w-2/3"></div>
          <div class="bg-accent animate-pulse rounded-md h-4 w-1/2"></div>
        </header>
        <section>
          <div class="bg-accent animate-pulse rounded-md aspect-square w-full"></div>
        </section>
      </div>
    </Layouts.app>
    """
  end
end
