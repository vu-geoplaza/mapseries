class AddFieldsToSheets < ActiveRecord::Migration[5.0]
  def change
    add_column :sheets, :auteurs, :text
    add_column :sheets, :metingen, :text
  end
end
