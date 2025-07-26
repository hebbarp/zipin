defmodule CreamSocial.Repo.Migrations.CreateEventRsvps do
  use Ecto.Migration

  def change do
    create table(:event_rsvps) do
      add :status, :string, null: false, default: "going"  # going, maybe, not_going
      add :response_note, :string        # Optional note from attendee
      add :checked_in, :boolean, default: false
      add :checked_in_at, :utc_datetime
      add :no_show, :boolean, default: false
      
      # Relations
      add :event_id, references(:events, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:event_rsvps, [:event_id])
    create index(:event_rsvps, [:user_id])
    create index(:event_rsvps, [:status])
    create unique_index(:event_rsvps, [:event_id, :user_id])
  end
end
