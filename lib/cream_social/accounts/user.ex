defmodule CreamSocial.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias CreamSocial.Accounts.User
  alias CreamSocial.Content.{Post, Like, Bookmark}
  alias CreamSocial.Social.{Follow, Channel}
  alias CreamSocial.Locations.City

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true
    field :full_name, :string
    field :phone_no, :string
    field :country_code, :string
    field :company, :string
    field :website, :string
    field :bio, :string
    field :profile_pic, :string
    field :subdomain, :string
    field :verified, :boolean, default: false
    field :active, :boolean, default: true
    field :subscription_plan, :string, default: "free"
    field :subscription_expires_at, :naive_datetime
    field :invite_code, :string
    field :category_id, :integer
    field :openai_api_key, :string

    belongs_to :referred_by, User, foreign_key: :referred_by_id
    has_many :referrals, User, foreign_key: :referred_by_id
    belongs_to :city, City

    has_many :posts, Post
    has_many :likes, Like
    has_many :bookmarks, Bookmark
    has_many :channels, Channel

    has_many :follower_relationships, Follow, foreign_key: :followed_id
    has_many :following_relationships, Follow, foreign_key: :follower_id
    has_many :followers, through: [:follower_relationships, :follower]
    has_many :following, through: [:following_relationships, :followed]

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :full_name, :phone_no, :country_code, 
                    :company, :website, :bio, :profile_pic, :subdomain, 
                    :verified, :active, :subscription_plan, :subscription_expires_at, 
                    :invite_code, :category_id, :referred_by_id])
    |> validate_required([:email, :password, :full_name])
    |> validate_email()
    |> validate_password()
    |> unique_constraint(:email)
    |> unique_constraint(:subdomain)
    |> unique_constraint(:invite_code)
    |> maybe_hash_password()
  end

  def registration_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> generate_invite_code()
  end

  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [:full_name, :phone_no, :country_code, :company, 
                    :website, :bio, :profile_pic, :subdomain, :category_id, :openai_api_key])
    |> validate_email()
    |> unique_constraint(:subdomain)
  end

  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_password()
    |> maybe_hash_password()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
  end

  defp maybe_hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      changeset
      |> validate_length(:password, min: 8, max: 72)
      |> put_change(:password_hash, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp generate_invite_code(changeset) do
    if get_field(changeset, :invite_code) do
      changeset
    else
      invite_code = 
        :crypto.strong_rand_bytes(4)
        |> Base.encode16()
        |> String.downcase()

      put_change(changeset, :invite_code, invite_code)
    end
  end

  def valid_password?(%User{password_hash: hash}, password)
      when is_binary(hash) and byte_size(password) > 0 do
    # Demo mode: accept "demo" password for demo hash
    if hash == "$2b$12$demo.hash.for.password.demo" and password == "demo" do
      true
    else
      Bcrypt.verify_pass(password, hash)
    end
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end
end