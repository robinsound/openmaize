defmodule Openmaize.LoginoutCheck do
  @moduledoc """
  Plug to check if the path is for the login or logout page and handles the
  login or logout if necessary. If the path is different, the connection is
  returned without any further checks being performed.

  If the path ends with `login` and it is a GET request, the current_user
  is set to nil and the user is sent straight to the login page. If the path
  ends with `login` and it is a POST request, Openmaize processes the login
  request and then, if successful, sends a token back to the user, either
  stored in a cookie or sent in the response body. If `redirects` is set to
  true, the user is redirected to the user's role's page.

  If the path ends with `logout` and the token is stored in a cookie, then
  the cookie is deleted. If `redirects` is set to true, the user is then
  redirected to the home page.

  There are two options:
  * redirects
      * if true, which is the default, redirect on login / logout
  * storage
      * storage method for the token -- the default is :cookie
      * if redirects is set to false, storage is automatically set to nil

  ## Examples

  Call LoginoutCheck without any options:

      plug Openmaize.LoginoutCheck

  Call LoginoutCheck and send the token in the response body:

      plug Openmaize.LoginoutCheck, storage: nil

  Call LoginoutCheck without redirects:

      plug Openmaize.LoginoutCheck, redirects: false

  """

  import Plug.Conn
  alias Openmaize.Login
  alias Openmaize.Logout

  @behaviour Plug

  def init(opts), do: opts

  @doc """
  Check the path and handle login or logout is necessary. If the path
  is not for the login or logout page, the connection is returned.
  """
  def call(%Plug.Conn{path_info: path_info} = conn, opts) do
    opts = {Keyword.get(opts, :redirects, true), Keyword.get(opts, :storage, :cookie)}
    case Enum.at(path_info, -1) do
      "login" -> handle_login(conn, opts)
      "logout" -> handle_logout(conn, opts)
      _ -> conn
    end
  end

  defp handle_login(%Plug.Conn{method: "POST"} = conn, opts), do: Login.call(conn, opts)
  defp handle_login(conn, _opts) do
    conn |> assign(:current_user, nil) |> put_private(:openmaize_skip, true)
  end

  defp handle_logout(conn, opts), do: assign(conn, :current_user, nil) |> Logout.call(opts)

end
