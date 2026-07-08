defmodule Popcorn.Repo.Migrations.RenameTerminalFields do
  use Ecto.Migration

  def change do
    rename table(:popcasts), :terminal_type, to: :term_type
    rename table(:popcasts), :terminal_line_height, to: :term_line_height
    rename table(:popcasts), :terminal_font_family, to: :term_font_family
    rename table(:popcasts), :theme_name, to: :term_theme_name
    rename table(:popcasts), :theme_fg, to: :term_theme_fg
    rename table(:popcasts), :theme_bg, to: :term_theme_bg
    rename table(:popcasts), :theme_palette, to: :term_theme_palette
    rename table(:popcasts), :cols, to: :term_cols
    rename table(:popcasts), :cols_override, to: :term_cols_override
    rename table(:popcasts), :rows, to: :term_rows
    rename table(:popcasts), :rows_override, to: :term_rows_override

    rename table(:streams), :terminal_line_height, to: :term_line_height
    rename table(:streams), :terminal_font_family, to: :term_font_family
    rename table(:streams), :theme_name, to: :term_theme_name
    rename table(:streams), :theme_prefer_original, to: :term_theme_prefer_original
    rename table(:streams), :theme_fg, to: :term_theme_fg
    rename table(:streams), :theme_bg, to: :term_theme_bg
    rename table(:streams), :theme_palette, to: :term_theme_palette
    rename table(:streams), :cols, to: :term_cols
    rename table(:streams), :rows, to: :term_rows

    rename table(:users), :terminal_font_family, to: :term_font_family
    rename table(:users), :theme_name, to: :term_theme_name
    rename table(:users), :theme_prefer_original, to: :term_theme_prefer_original
  end
end
