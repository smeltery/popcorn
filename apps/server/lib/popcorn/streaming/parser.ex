defmodule Popcorn.Streaming.Parser do
  @callback name() :: binary
  @callback init() :: term
  @callback parse({message :: term, opts :: keyword}, term) ::
              {:ok, [{atom, term}], term} | {:error, term}
  @callback supported_commands() :: [atom]

  alias Popcorn.Streaming.Parser

  def get("raw"), do: %{impl: Parser.Raw, state: Parser.Raw.init()}
  def get("v1.alis"), do: %{impl: Parser.AlisV1, state: Parser.AlisV1.init()}
  def get("v2.popcast"), do: %{impl: Parser.PopcastV2, state: Parser.PopcastV2.init()}
  def get("v3.popcast"), do: %{impl: Parser.PopcastV3, state: Parser.PopcastV3.init()}
end
