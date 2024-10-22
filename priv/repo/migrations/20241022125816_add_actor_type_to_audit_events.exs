defmodule Lightning.Repo.Migrations.AddActorTypeToAuditEvents do
  use Ecto.Migration

  def change do
    alter table(:audit_events) do
      add :actor_type, :string, null: false, default: "Lightning.Accounts.User"
    end
  end
end
