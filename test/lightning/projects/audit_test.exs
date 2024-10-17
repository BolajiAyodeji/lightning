defmodule Lightning.Projects.AuditTest do
  use Lightning.DataCase, async: true

  alias Ecto.Multi

  alias Lightning.Projects.Audit
  alias Lightning.Projects.Project

  describe ".history_retention_period_updated" do
    setup do
      project =
        insert(
          :project,
          dataclip_retention_period: 14,
          history_retention_period: 90,
          retention_policy: :retain_all
        )

      user = insert(:user)

      %{
        project: project,
        user: user
      }
    end

    test "adds operation to multi if history retention period is updated", %{
      project: %{id: project_id} = project,
      user: %{id: user_id} = user
    } do
      attrs = %{
        dataclip_retention_period: 7,
        history_retention_period: 30,
        retention_policy: :retain_with_errors
      }

      changeset = project |> Project.changeset(attrs)

      [audit_history_retention: {:insert, changeset, []}] =
        Multi.new()
        |> Audit.history_retention_period_updated(changeset, user)
        |> Multi.to_list()

      assert %{
               changes: %{
                 event: "history_retention_period_updated",
                 item_type: "project",
                 item_id: ^project_id,
                 actor_id: ^user_id,
                 changes: %{
                   changes: %{
                     before: %{history_retention_period: 90},
                     after: %{history_retention_period: 30}
                   }
                 }
               },
               valid?: true
             } = changeset
    end

    test "does not add operation if history retention period is unchanged", %{
      project: project,
      user: user
    } do
      attrs = %{
        dataclip_retention_period: 7,
        history_retention_period: 90,
        retention_policy: :retain_with_errors
      }

      changeset = project |> Project.changeset(attrs)

      updated_multi =
        Multi.new()
        |> Audit.history_retention_period_updated(changeset, user)
        |> Multi.to_list()

      assert updated_multi == []
    end
  end

  describe ".dataclip_retention_period_updated" do
    setup do
      project =
        insert(
          :project,
          dataclip_retention_period: 14,
          history_retention_period: 90,
          retention_policy: :retain_all
        )

      user = insert(:user)

      %{
        project: project,
        user: user
      }
    end

    test "adds operation to multi if dataclip retention period is updated", %{
      project: %{id: project_id} = project,
      user: %{id: user_id} = user
    } do
      attrs = %{
        dataclip_retention_period: 7,
        history_retention_period: 30,
        retention_policy: :retain_with_errors
      }

      changeset = project |> Project.changeset(attrs)

      [audit_dataclip_retention: {:insert, changeset, []}] =
        Multi.new()
        |> Audit.dataclip_retention_period_updated(changeset, user)
        |> Multi.to_list()

      assert %{
               changes: %{
                 event: "dataclip_retention_period_updated",
                 item_type: "project",
                 item_id: ^project_id,
                 actor_id: ^user_id,
                 changes: %{
                   changes: %{
                     before: %{dataclip_retention_period: 14},
                     after: %{dataclip_retention_period: 7}
                   }
                 }
               },
               valid?: true
             } = changeset
    end

    test "does not add operation if dataclip retention period is unchanged", %{
      project: project,
      user: user
    } do
      attrs = %{
        dataclip_retention_period: 14,
        history_retention_period: 30,
        retention_policy: :retain_with_errors
      }

      changeset = project |> Project.changeset(attrs)

      updated_multi =
        Multi.new()
        |> Audit.dataclip_retention_period_updated(changeset, user)
        |> Multi.to_list()

      assert updated_multi == []
    end
  end
end
