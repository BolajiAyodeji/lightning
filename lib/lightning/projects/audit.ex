defmodule Lightning.Projects.Audit do
  @moduledoc """
  Generate Audit changesets for selected changes to project settings.
  """
  use Lightning.Auditing.Audit,
    repo: Lightning.Repo,
    item: "project",
    events: [
      "dataclip_retention_period_updated",
      "history_retention_period_updated"
    ]

  alias Ecto.Multi

  require Logger

  def history_retention_period_updated(multi, changeset, user) do
    event_changeset(:history_retention_period, changeset, user)
    |> maybe_extend_multi(multi, :audit_history_retention)
  end

  def dataclip_retention_period_updated(multi, changeset, user) do
    event_changeset(:dataclip_retention_period, changeset, user)
    |> maybe_extend_multi(multi, :audit_dataclip_retention)
  end

  defp event_changeset(field, %{data: %{id: project_id}} = changeset, user) do
    "#{field}_updated"
    |> event(project_id, user.id, filter_changes(changeset, field))
  end

  defp maybe_extend_multi(:no_changes, multi, _op_name), do: multi

  defp maybe_extend_multi(audit_changeset, multi, op_name) do
    multi |> Multi.insert(op_name, audit_changeset)
  end

  defp filter_changes(%{changes: changes} = changeset, field) do
    changeset |> Map.merge(%{changes: changes |> Map.take([field])})
  end
end
