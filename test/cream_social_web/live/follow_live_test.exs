defmodule CreamSocialWeb.FollowLiveTest do
  use CreamSocialWeb.ConnCase

  import Phoenix.LiveViewTest
  import CreamSocial.SocialFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_follow(_) do
    follow = follow_fixture()
    %{follow: follow}
  end

  describe "Index" do
    setup [:create_follow]

    test "lists all follows", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/follows")

      assert html =~ "Listing Follows"
    end

    test "saves new follow", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/follows")

      assert index_live |> element("a", "New Follow") |> render_click() =~
               "New Follow"

      assert_patch(index_live, ~p"/follows/new")

      assert index_live
             |> form("#follow-form", follow: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#follow-form", follow: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/follows")

      html = render(index_live)
      assert html =~ "Follow created successfully"
    end

    test "updates follow in listing", %{conn: conn, follow: follow} do
      {:ok, index_live, _html} = live(conn, ~p"/follows")

      assert index_live |> element("#follows-#{follow.id} a", "Edit") |> render_click() =~
               "Edit Follow"

      assert_patch(index_live, ~p"/follows/#{follow}/edit")

      assert index_live
             |> form("#follow-form", follow: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#follow-form", follow: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/follows")

      html = render(index_live)
      assert html =~ "Follow updated successfully"
    end

    test "deletes follow in listing", %{conn: conn, follow: follow} do
      {:ok, index_live, _html} = live(conn, ~p"/follows")

      assert index_live |> element("#follows-#{follow.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#follows-#{follow.id}")
    end
  end

  describe "Show" do
    setup [:create_follow]

    test "displays follow", %{conn: conn, follow: follow} do
      {:ok, _show_live, html} = live(conn, ~p"/follows/#{follow}")

      assert html =~ "Show Follow"
    end

    test "updates follow within modal", %{conn: conn, follow: follow} do
      {:ok, show_live, _html} = live(conn, ~p"/follows/#{follow}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Follow"

      assert_patch(show_live, ~p"/follows/#{follow}/show/edit")

      assert show_live
             |> form("#follow-form", follow: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#follow-form", follow: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/follows/#{follow}")

      html = render(show_live)
      assert html =~ "Follow updated successfully"
    end
  end
end
