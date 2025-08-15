defmodule Zipin.Application do
  @moduledoc false
  use Application

  @impl true
  def start(type, args) do
    CreamSocial.Application.start(type, args)
  end

  @impl true
  def config_change(changed, new, removed) do
    CreamSocial.Application.config_change(changed, new, removed)
  end
end
