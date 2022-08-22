defmodule LightningWeb.CredentialLiveTest do
  use LightningWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Lightning.CredentialsFixtures

  alias Lightning.Credentials

  @create_attrs %{
    body: "some body",
    name: "some name"
  }
  @update_attrs %{
    body: "some updated body",
    name: "some updated name"
  }
  @invalid_attrs %{body: nil, name: nil}

  defp create_credential(%{user: user}) do
    credential = credential_fixture(user_id: user.id)
    %{credential: credential}
  end

  defp create_project_credential(%{user: user}) do
    project_credential = project_credential_fixture(user_id: user.id)
    %{project_credential: project_credential}
  end

  setup :register_and_log_in_user
  setup :create_project_for_current_user

  describe "Index" do
    setup [:create_credential, :create_project_credential]

    test "Side menu has credentials and user profile navigation", %{
      conn: conn
    } do
      {:ok, index_live, _html} =
        live(conn, Routes.credential_index_path(conn, :index))

      # This path does not exist yet
      # assert index_live
      #        |> element("nav#side-menu a", "User Profile")
      #        |> render_click()
      #        |> follow_redirect(
      #          conn,
      #          Routes.profile_index_path(conn, :index)
      #        )

      assert index_live
             |> element("nav#side-menu a", "Credentials")
             |> render_click()
             |> follow_redirect(
               conn,
               Routes.credential_index_path(conn, :index)
             )
    end

    test "lists all credentials", %{
      conn: conn,
      credential: credential,
      project_credential: project_credential
    } do
      {:ok, _index_live, html} =
        live(conn, Routes.credential_index_path(conn, :index))

      assert html =~ "Credentials"

      assert html =~
               credential.name |> Phoenix.HTML.Safe.to_iodata() |> to_string()

      [[], project_names] =
        Credentials.list_credentials_for_user(credential.user_id)
        |> Enum.map(fn c ->
          Enum.map(c.projects, fn p -> p.name end)
        end)

      assert html =~ project_names |> Enum.join(", ")

      assert html =~ "Edit"
      assert html =~ "Delete"
      assert html =~ "Production"
    end

    test "saves new credential", %{conn: conn, project: project} do
      {:ok, index_live, _html} =
        live(conn, Routes.credential_index_path(conn, :index))

      {:ok, edit_live, _html} =
        index_live
        |> element("a", "New Credential")
        |> render_click()
        |> follow_redirect(
          conn,
          Routes.credential_edit_path(conn, :new)
        )

      assert edit_live
             |> form("#credential-form", credential: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert edit_live
             |> form("#credential-form", credential: @create_attrs)
             |> render_change()

      edit_live
      |> element("#project_list")
      |> render_hook("select_item", %{"id" => project.id})

      edit_live
      |> element("button", "Add")
      |> render_click()

      edit_live
      |> form("#credential-form")
      |> render_submit()
    end

    test "deletes credential in listing", %{conn: conn, credential: credential} do
      {:ok, index_live, _html} =
        live(
          conn,
          Routes.credential_index_path(conn, :index)
        )

      assert index_live
             |> element("#credential-#{credential.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#credential-#{credential.id}")
    end
  end

  describe "Edit" do
    setup [:create_credential]

    test "updates credential in listing", %{conn: conn, credential: credential} do
      {:ok, index_live, _html} =
        live(conn, Routes.credential_index_path(conn, :index))

      {:ok, form_live, _} =
        index_live
        |> element("#credential-#{credential.id} a", "Edit")
        |> render_click()
        |> follow_redirect(
          conn,
          Routes.credential_edit_path(conn, :edit, credential)
        )

      assert form_live
             |> form("#credential-form", credential: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert form_live
             |> form("#credential-form", credential: @update_attrs)
             |> render_submit() =~ "some updated body"
    end

    test "marks a credential for use in a 'production' system", %{
      conn: conn,
      credential: credential
    } do
      {:ok, index_live, _html} =
        live(conn, Routes.credential_index_path(conn, :index))

      {:ok, form_live, _} =
        index_live
        |> element("#credential-#{credential.id} a", "Edit")
        |> render_click()
        |> follow_redirect(
          conn,
          Routes.credential_edit_path(conn, :edit, credential)
        )

      assert form_live
             |> form("#credential-form",
               credential: Map.put(@update_attrs, :production, true)
             )
             |> render_submit() =~ "some updated body"
    end
  end
end
