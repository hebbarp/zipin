# Password reset script
alias CreamSocial.Accounts

# Create a test user with known password
case Accounts.create_user(%{
  email: "admin@zipin.app", 
  password: "Admin123!",
  username: "admin",
  full_name: "Admin User"
}) do
  {:ok, user} -> 
    IO.puts("✅ Created admin user: admin@zipin.app")
    IO.puts("Password: Admin123!")
    IO.puts("User ID: #{user.id}")
  {:error, changeset} -> 
    IO.puts("❌ Error creating user:")
    IO.inspect(changeset.errors)
end

# List all existing users
users = Accounts.list_users()
IO.puts("\n📋 Existing users:")
Enum.each(users, fn user ->
  IO.puts("- #{user.email} (ID: #{user.id})")
end)