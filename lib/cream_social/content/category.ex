defmodule CreamSocial.Content.Category do
  use Ecto.Schema
  import Ecto.Changeset
  alias CreamSocial.Content.Post

  schema "categories" do
    field :name, :string
    field :description, :string
    field :slug, :string
    field :color, :string
    field :icon, :string
    field :active, :boolean, default: true

    has_many :posts, Post

    timestamps()
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :description, :slug, :color, :icon, :active])
    |> validate_required([:name, :slug])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/, message: "must be lowercase letters, numbers, and dashes only")
    |> unique_constraint(:slug)
  end
end