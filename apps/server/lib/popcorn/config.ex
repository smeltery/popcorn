defmodule Popcorn.Config do
  defmacro __using__(_) do
    quote do
      def config do
        Popcorn.AppEnv.get(__MODULE__, [])
      end

      def config(key, default \\ nil) do
        Keyword.get(config(), key, default)
      end
    end
  end
end
