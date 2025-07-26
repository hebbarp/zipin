defmodule CreamSocialWeb.PageController do
  use CreamSocialWeb, :controller

  def home(conn, _params) do
    if conn.assigns[:current_user] do
      redirect(conn, to: "/stream")
    else
      redirect(conn, to: "/auth/login")
    end
  end
end
