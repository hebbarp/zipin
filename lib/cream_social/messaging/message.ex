defmodule CreamSocial.Messaging.Message do
  use Ecto.Schema
  import Ecto.Changeset
  alias CreamSocial.Accounts.User

  schema "messages" do
    field :content, :string
    field :read_at, :naive_datetime

    belongs_to :sender, User, foreign_key: :sender_id
    belongs_to :recipient, User, foreign_key: :recipient_id

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :sender_id, :recipient_id, :read_at])
    |> validate_required([:content, :sender_id, :recipient_id])
    |> validate_length(:content, min: 1, max: 2000)
    |> validate_different_users()
    |> foreign_key_constraint(:sender_id)
    |> foreign_key_constraint(:recipient_id)
  end

  defp validate_different_users(changeset) do
    sender_id = get_field(changeset, :sender_id)
    recipient_id = get_field(changeset, :recipient_id)

    if sender_id && recipient_id && sender_id == recipient_id do
      add_error(changeset, :recipient_id, "cannot send message to yourself")
    else
      changeset
    end
  end
end