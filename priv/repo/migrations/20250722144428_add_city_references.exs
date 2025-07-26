defmodule CreamSocial.Repo.Migrations.AddCityReferences do
  use Ecto.Migration

  def change do
    # Add city reference to users
    alter table(:users) do
      add :city_id, references(:cities, on_delete: :nilify_all)
    end

    # Add city reference to places
    alter table(:places) do
      add :city_id, references(:cities, on_delete: :delete_all)
    end

    create index(:users, [:city_id])
    create index(:places, [:city_id])
  end
end
