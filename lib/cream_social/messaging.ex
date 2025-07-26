defmodule CreamSocial.Messaging do
  @moduledoc """
  The Messaging context.
  """

  import Ecto.Query, warn: false
  alias CreamSocial.Repo
  alias CreamSocial.Messaging.Message
  alias CreamSocial.Accounts.User

  def list_conversations(%User{} = user) do
    # Get all unique conversation partners and their latest message info
    from(m in Message,
      where: m.sender_id == ^user.id or m.recipient_id == ^user.id,
      distinct: true,
      select: %{
        other_user_id: fragment("CASE WHEN ? = ? THEN ? ELSE ? END", m.sender_id, ^user.id, m.recipient_id, m.sender_id),
        inserted_at: m.inserted_at,
        is_unread: fragment("CASE WHEN ? = ? AND ? IS NULL THEN 1 ELSE 0 END", m.recipient_id, ^user.id, m.read_at)
      },
      order_by: [desc: m.inserted_at]
    )
    |> Repo.all()
    |> Enum.group_by(& &1.other_user_id)
    |> Enum.map(fn {other_user_id, messages} ->
      %{
        other_user_id: other_user_id,
        last_message_at: messages |> Enum.map(& &1.inserted_at) |> Enum.max(),
        unread_count: messages |> Enum.map(& &1.is_unread) |> Enum.sum()
      }
    end)
    |> Enum.sort_by(& &1.last_message_at, {:desc, NaiveDateTime})
  end

  def list_messages(%User{} = user1, %User{} = user2) do
    from(m in Message,
      where: (m.sender_id == ^user1.id and m.recipient_id == ^user2.id) or
             (m.sender_id == ^user2.id and m.recipient_id == ^user1.id),
      preload: [:sender, :recipient],
      order_by: [asc: m.inserted_at]
    )
    |> Repo.all()
  end

  def create_message(attrs \\ %{}) do
    case %Message{}
         |> Message.changeset(attrs)
         |> Repo.insert() do
      {:ok, message} ->
        # Broadcast the new message to both users
        message = Repo.preload(message, [:sender, :recipient])
        Phoenix.PubSub.broadcast(
          CreamSocial.PubSub,
          "messages:#{message.sender_id}",
          {:new_message, message}
        )
        Phoenix.PubSub.broadcast(
          CreamSocial.PubSub,
          "messages:#{message.recipient_id}",
          {:new_message, message}
        )
        {:ok, message}
      
      error -> error
    end
  end

  def mark_messages_as_read(%User{} = user, %User{} = sender) do
    from(m in Message,
      where: m.recipient_id == ^user.id and m.sender_id == ^sender.id and is_nil(m.read_at)
    )
    |> Repo.update_all(set: [read_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)])
  end

  def get_unread_count(%User{} = user) do
    from(m in Message,
      where: m.recipient_id == ^user.id and is_nil(m.read_at),
      select: count(m.id)
    )
    |> Repo.one()
  end
end