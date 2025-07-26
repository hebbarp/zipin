defmodule CreamSocial.Content.LinkPreview do
  use Ecto.Schema
  import Ecto.Changeset

  schema "link_previews" do
    field :url, :string
    field :title, :string
    field :description, :string
    field :image_url, :string
    field :site_name, :string
    field :cached_at, :naive_datetime

    timestamps()
  end

  def changeset(link_preview, attrs) do
    link_preview
    |> cast(attrs, [:url, :title, :description, :image_url, :site_name, :cached_at])
    |> validate_required([:url])
    |> validate_format(:url, ~r/^https?:\/\//)
    |> unique_constraint(:url)
  end
end