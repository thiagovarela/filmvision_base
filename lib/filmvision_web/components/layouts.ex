defmodule FilmvisionWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use FilmvisionWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <aside
      id="main-sidebar"
      class="sidebar"
      data-side="left"
      aria-hidden="false"
      phx-hook="BasecoatHook"
      data-basecoat="sidebar"
    >
      <nav aria-label="Sidebar navigation">
        <header>
          <a href="/" class="btn-ghost p-2 h-12 w-full justify-start">
            <div class=" flex aspect-square size-8 items-center justify-center rounded-lg">
              <.icon name="ri-layout-masonry-line" class="ri-2x" />
            </div>
            <div class="grid flex-1 text-left text-sm leading-tight">
              <span class="truncate font-medium">Film Vision</span>
            </div>
          </a>
        </header>
        <section class="scrollbar">
          <div role="group" aria-labelledby="group-label-content-1">
            <h3 id="group-label-content-1">Getting Started</h3>

            <ul>
              <li>
                <.link href={~p"/onboarding"}>
                  <.icon name="ri-home-9-line" class="ri-lg" />
                  <span>Home</span>
                </.link>
              </li>

              <li>
                <a href="/analytics">
                  <.icon name="ri-line-chart-line" class="ri-lg" />
                  <span>Analytics</span>
                </a>
              </li>
            </ul>
          </div>
        </section>
        <footer>
          <div
            id="demo-dropdown-menu"
            class="dropdown-menu"
          >
            <button
              id="demo-dropdown-menu-trigger"
              type="button"
              aria-expanded="false"
              aria-haspopup="menu"
              aria-controls="demo-dropdown-menu-menu"
              data-keep-mobile-sidebar-open="true"
              class="btn-ghost p-2 h-12 w-full flex items-center justify-start"
            >
              <img
                src={
                  @current_scope.user.image_url ||
                    "https://ui-avatars.com/api/?name=#{URI.encode(@current_scope.user.name || @current_scope.user.email)}&background=random"
                }
                class="rounded-lg shrink-0 size-8"
                alt="User avatar"
              />
              <div class="grid flex-1 text-left text-sm leading-tight">
                <span class="truncate font-medium">
                  {@current_scope.user.name || @current_scope.user.email}
                </span>
                <span class="truncate text-xs">
                  {@current_scope.user.email}
                </span>
              </div>
              <.icon name="ri-expand-up-down-line" />
            </button>

            <div
              id="account-dropdown-menu-popover"
              data-side="top"
              data-align="start"
              data-popover
              aria-hidden="true"
              class="min-w-56"
            >
              <div
                role="menu"
                id="account-dropdown-menu-menu"
                aria-labelledby="account-dropdown-menu-trigger"
              >
                <div role="group" aria-labelledby="account-options">
                  <.link role="menuitem" href={~p"/users/settings"}>
                    Settings
                  </.link>
                  <div role="menuitem">
                    Subscriptions
                  </div>
                </div>
                <hr role="separator" />
                <div role="menuitem">Support</div>
                <div role="menuitem" aria-disabled="true">Feedback</div>
                <hr role="separator" />
                <.link role="menuitem" href={~p"/users/log-out"} method="delete">Logout</.link>
              </div>
            </div>
          </div>
        </footer>
      </nav>
    </aside>
    <main>
      <header class="bg-background sticky inset-x-0 top-0 isolate flex shrink-0 items-center gap-2 border-b z-10">
        <div class="flex h-14 w-full items-center gap-2 px-4">
          <button
            type="button"
            aria-label="Toggle sidebar"
            data-tooltip="Toggle sidebar"
            data-side="bottom"
            data-align="start"
            phx-click={JS.dispatch("basecoat:sidebar", detail: %{id: "main-sidebar"})}
            class="btn-sm-icon-ghost mr-auto size-7 -ml-1.5"
          >
            <.icon name="ri-side-bar-line" class="ri-lg" />
          </button>
          <%= if @current_scope do %>
            <select
              class="select h-8 leading-none"
              id="project-select"
              name="project_id"
              phx-change="project_selected"
            >
              <option value="">All Projects</option>
              <%= for project <- @current_scope.user_projects || [] do %>
                <option value={project.id} selected={project.id == @current_scope.current_project_id}>
                  {project.name}
                </option>
              <% end %>
            </select>
          <% end %>

          <button
            type="button"
            aria-label="Toggle dark mode"
            data-tooltip="Toggle dark mode"
            data-side="bottom"
            phx-click={JS.dispatch("basecoat:theme")}
            class="btn-icon-outline size-8"
          >
            <span class="hidden dark:block">
              <.icon name="ri-moon-line" class="ri-lg" />
            </span>
            <span class="block dark:hidden">
              <.icon name="ri-moon-fill" class="ri-lg" />
            </span>
          </button>
        </div>
      </header>
      <div class="pt-10 px-2 md:px-16 max-w-3xl">
        <div class="">
          {render_slot(@inner_block)}
        </div>
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true
  attr :flash, :map, required: true, doc: "the map of flash messages"

  def site(assigns) do
    ~H"""
    <header></header>
    <main class="px-4 sm:px-6 lg:px-8 h-full">
      <div>
        {render_slot(@inner_block)}
      </div>
    </main>
    """
  end

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true
  attr :flash, :map, required: true, doc: "the map of flash messages"

  def auth(assigns) do
    ~H"""
    <header></header>
    <main class="px-4 sm:px-6 lg:px-8 h-full">
      <div>
        <div class="min-h-screen flex items-center justify-center">
          <div class="w-full max-w-md">
            {render_slot(@inner_block)}
          </div>
        </div>
      </div>
    </main>
    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div
      id={@id}
      aria-live="polite"
      phx-hook="FlashToaster"
    >
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="ri-arrow-right" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="ri-arrow-right" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
