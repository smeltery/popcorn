defmodule Popcorn.Emails.Mailer do
  use Swoosh.Mailer, otp_app: :popcorn

  def local_adapter? do
    Keyword.fetch!(Application.fetch_env!(:popcorn, __MODULE__), :adapter) ==
      Swoosh.Adapters.Local
  end
end
