class AddOrgToUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :libraries_users, id: false do |t|
      t.string :library_abbr
      t.belongs_to :user, foreign_key: true
    end
    add_foreign_key :libraries_users, :libraries, primary_key: :abbr, column: 'library_abbr'
    add_index :libraries_users, [:user_id, :library_abbr], :unique => true, :name => 'by_users_and_libraries'
  end
end
