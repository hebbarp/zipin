defmodule CreamSocialWeb.LiveHelpers do
  @moduledoc """
  Helper functions for LiveViews
  """

  def time_ago(datetime) when is_nil(datetime), do: ""

  def time_ago(datetime) do
    now = NaiveDateTime.utc_now()
    diff = NaiveDateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "#{diff}s"
      diff < 3600 -> "#{div(diff, 60)}m"
      diff < 86400 -> "#{div(diff, 3600)}h"
      diff < 2592000 -> "#{div(diff, 86400)}d"
      true -> "#{div(diff, 2592000)}mo"
    end
  end
end