defmodule CreamSocial.Repo.Migrations.AddImagesToPlacesAndEvents do
  use Ecto.Migration

  def change do
    # Add image support to places
    alter table(:places) do
      add :image_url, :string  # URL or path to the main image
      add :images, :map        # JSON array for multiple images (future use)
    end

    # Add image support to events  
    alter table(:events) do
      add :image_url, :string  # URL or path to the main event image
      add :images, :map        # JSON array for multiple images (future use)
    end

    # Add indexes for image queries
    create index(:places, [:image_url])
    create index(:events, [:image_url])
  end
end