defmodule Filmvision do
  @moduledoc """
  Filmvision keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  defmodule Schema do
    defmacro __using__(_) do
      quote do
        use Ecto.Schema

        @primary_key {:id, UUIDv7.Type, autogenerate: true}
        @foreign_key_type UUIDv7.Type
      end
    end
  end
end
