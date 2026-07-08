defmodule PopcornWeb.OembedXML do
  use Phoenix.Component
  alias PopcornWeb.OembedJSON

  embed_templates "oembed_xml/*"

  def show(assigns) do
    ~H"""
    <.rich {OembedJSON.show(assigns)} />
    """
  end
end
