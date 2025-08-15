# Create test user script
alias CreamSocial.Accounts

IO.puts("🔍 Testing database connection...")
case CreamSocial.Repo.query("SELECT 1") do
  {:ok, _} -> IO.puts("✅ Database connection works!")
  {:error, error} -> IO.puts("❌ Database error: #{inspect(error)}")
end

IO.puts("\n📋 Existing users:")
users = Accounts.list_users()
Enum.each(users, fn user ->
  IO.puts("- #{user.email} (ID: #{user.id})")
end)

IO.puts("\n👤 Creating test user...")
case Accounts.create_user(%{
  email: "test@example.com", 
  password: "TestPass123!", 
  username: "testuser", 
  full_name: "Test User"
}) do
  {:ok, user} -> 
    IO.puts("✅ Created user: test@example.com")
    IO.puts("🔑 Password: TestPass123!")
    IO.puts("🆔 User ID: #{user.id}")
  {:error, changeset} -> 
    IO.puts("❌ Error creating user:")
    IO.inspect(changeset.errors)
end

IO.puts("\n🔐 Testing password verification...")
user = Accounts.get_user_by_email("test@example.com")
if user do
  case Bcrypt.verify_pass("TestPass123!", user.hashed_password) do
    true -> IO.puts("✅ Password verification works!")
    false -> IO.puts("❌ Password verification failed!")
  end
else
  IO.puts("❌ User not found!")
end