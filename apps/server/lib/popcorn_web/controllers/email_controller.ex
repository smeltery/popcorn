defmodule PopcornWeb.EmailController do
  use PopcornWeb, :controller

  plug :require_current_user

  def edit(conn, %{"t" => token}) do
    case Popcorn.verify_email_change(conn.assigns.current_user, token) do
      {:ok, email} ->
        render(conn, "edit.html", token: token, email: email)

      {:error, :invalid_token} ->
        conn
        |> put_flash(:error, "Invalid or expired link")
        |> redirect(to: ~p"/user/edit")

      {:error, :user_mismatch} ->
        conn
        |> put_flash(:error, "Email not updated - the link was generated for another account")
        |> redirect(to: ~p"/user/edit")

      {:error, :email_changed} ->
        conn
        |> put_flash(:error, "Email not updated - the link is no longer valid")
        |> redirect(to: ~p"/user/edit")
    end
  end

  def edit(conn, _params) do
    conn
    |> put_flash(:error, "Invalid or expired link")
    |> redirect(to: ~p"/user/edit")
  end

  def update(conn, %{"user" => %{"email" => email}}) do
    case Popcorn.initiate_email_change(
           conn.assigns.current_user,
           email,
           PopcornWeb.UrlProvider
         ) do
      {:ok, :changed} ->
        redirect(conn, to: ~p"/user/edit")

      {:ok, {:pending, email}} ->
        redirect(conn, to: ~p"/user/edit?ec-status=pending&ec-addr=#{email}")

      {:error, reason} ->
        redirect(conn, to: ~p"/user/edit?ec-status=#{reason}")
    end
  end

  def update(conn, %{"t" => token}) do
    case Popcorn.confirm_email_change(conn.assigns.current_user, token) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Email address has been changed")
        |> redirect(to: ~p"/user/edit")

      {:error, :invalid_token} ->
        conn
        |> put_flash(:error, "Email not updated - invalid or expired link")
        |> redirect(to: ~p"/user/edit")

      {:error, :email_taken} ->
        conn
        |> put_flash(:error, "Email not updated - this address belongs to another account")
        |> redirect(to: ~p"/user/edit")

      {:error, :user_mismatch} ->
        conn
        |> put_flash(:error, "Email not updated - the link was generated for another account")
        |> redirect(to: ~p"/user/edit")

      {:error, :email_changed} ->
        conn
        |> put_flash(:error, "Email not updated - the link is no longer valid")
        |> redirect(to: ~p"/user/edit")
    end
  end

  def update(conn, _params) do
    conn
    |> put_flash(:error, "Invalid or expired link")
    |> redirect(to: ~p"/user/edit")
  end
end
