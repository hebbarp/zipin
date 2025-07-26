defmodule CreamSocial.Repo.Migrations.AddUniquePlaceNameAreaIndex do
  use Ecto.Migration

  def change do
    create unique_index(:places, [:name, :area], name: :unique_place_name_area)
  end
end
