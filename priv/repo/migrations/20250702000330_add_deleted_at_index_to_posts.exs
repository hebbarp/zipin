defmodule CreamSocial.Repo.Migrations.AddDeletedAtIndexToPosts do
  use Ecto.Migration

  def change do
    create_if_not_exists index(:posts, [:deleted_at])
  end
end
