defmodule CreamSocial.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :full_name, :string, null: false
      add :phone_no, :string
      add :country_code, :string
      add :company, :string
      add :website, :string
      add :bio, :text
      add :profile_pic, :string
      add :subdomain, :string
      add :verified, :boolean, default: false
      add :active, :boolean, default: true
      add :subscription_plan, :string, default: "free"
      add :subscription_expires_at, :naive_datetime
      add :invite_code, :string
      add :referred_by_id, references(:users, on_delete: :nilify_all)
      add :category_id, :integer

      timestamps()
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:subdomain])
    create unique_index(:users, [:invite_code])
    create index(:users, [:referred_by_id])
    create index(:users, [:category_id])
  end
end