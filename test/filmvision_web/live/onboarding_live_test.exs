defmodule FilmvisionWeb.OnboardingLiveTest do
  use FilmvisionWeb.ConnCase

  import Phoenix.LiveViewTest
  import Filmvision.AccountsFixtures

  describe "onboarding page" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "displays welcome message and method selection", %{conn: conn, user: user} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/onboarding")

      assert html =~ ""
    end
  end
end
