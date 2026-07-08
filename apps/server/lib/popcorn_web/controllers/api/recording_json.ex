defmodule PopcornWeb.Api.RecordingJSON do
  use PopcornWeb, :json
  alias PopcornWeb.UrlHelpers
  alias Popcorn.Accounts
  alias Ecto.Changeset

  def show(%{popcast: popcast, cli: cli}) do
    url = url(~p"/a/#{popcast}")
    file_url = UrlHelpers.popcast_file_url(popcast)

    %{
      id: popcast.id,
      url: url,
      file_url: file_url,
      audio_url: popcast.audio_url,
      title: popcast.title,
      description: popcast.description,
      visibility: popcast.visibility,
      message: message(url, cli)
    }
  end

  def error(%{reason: reason} = assigns) do
    case reason do
      :unauthenticated ->
        %{type: "unauthenticated", message: "Unauthenticated"}

      :not_found ->
        %{type: "not_found", message: "Recording not found"}

      %Changeset{} = changeset ->
        details = translate_errors(changeset)
        %{type: "validation_failed", message: "Validation failed", details: details}

      :invalid_format ->
        %{type: "validation_failed", message: "This doesn't look like a valid popcast file"}

      :empty_recording ->
        %{type: "validation_failed", message: "This recording has no events"}

      {:invalid_version, version} ->
        %{type: "validation_failed", message: "popcast v#{version} is not supported"}

      :upload_limit ->
        %{type: "upload_limit_reached", message: "Upload limit reached"}

      :account_required ->
        %{type: "account_required", message: "This action requires an account"}
    end
    |> Map.merge(Map.take(assigns, [:message]))
  end

  defp message(url, cli) do
    %{token: install_id} = cli

    message = """
    View the recording at:

        #{url}
    """

    ttl = Popcorn.unclaimed_recording_ttl()

    if !Accounts.cli_registered?(cli) && ttl do
      hostname = PopcornWeb.instance_hostname()
      url = url(~p"/connect/#{install_id}")

      """
      #{message}
      This popcorn CLI hasn't been linked to any #{hostname} account.

      Recordings uploaded from unrecognized systems, such as this one, are automatically
      deleted #{ttl} days after upload.

      If you want to preserve all recordings uploaded from this machine,
      authenticate this CLI with your #{hostname} account by opening the following link:

          #{url}
      """
    else
      message
    end
  end

  def translate_errors(changeset) do
    for {field, errors} <- changeset.errors do
      %{field: field, message: translate_error(errors)}
    end
  end
end
