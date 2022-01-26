class AddVolgnummerToCopies < ActiveRecord::Migration[5.0]
  def change
    add_column :copies, :volgnummer, :text
  end
end
