defmodule CreamSocial.Events.EventRsvp do
  use Ecto.Schema
  import Ecto.Changeset
  alias CreamSocial.Events.Event
  alias CreamSocial.Accounts.User

  schema "event_rsvps" do
    field :status, :string, default: "going"
    field :response_note, :string
    field :checked_in, :boolean, default: false
    field :checked_in_at, :utc_datetime
    field :no_show, :boolean, default: false

    # Associations
    belongs_to :event, Event
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(rsvp, attrs) do
    rsvp
    |> cast(attrs, [
      :status, :response_note, :checked_in, :checked_in_at, 
      :no_show, :event_id, :user_id
    ])
    |> validate_required([:status, :event_id, :user_id])
    |> validate_inclusion(:status, ["going", "maybe", "not_going"])
    |> validate_length(:response_note, max: 500)
    |> unique_constraint([:event_id, :user_id])
    |> foreign_key_constraint(:event_id)
    |> foreign_key_constraint(:user_id)
  end

  def status_options do
    [
      {"Going", "going"},
      {"Maybe", "maybe"},
      {"Not Going", "not_going"}
    ]
  end

  def status_display(status) do
    case status do
      "going" -> "Going"
      "maybe" -> "Maybe"
      "not_going" -> "Not Going"
      _ -> "Unknown"
    end
  end

  def status_icon(status) do
    case status do
      "going" -> "✅"
      "maybe" -> "🤔"
      "not_going" -> "❌"
      _ -> "❓"
    end
  end
end