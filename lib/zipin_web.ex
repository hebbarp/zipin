defmodule ZipinWeb do
  @moduledoc false
  defmacro __using__(which) do
    apply(CreamSocialWeb, :__using__, [which])
  end
end
