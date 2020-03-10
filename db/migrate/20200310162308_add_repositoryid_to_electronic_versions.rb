class AddRepositoryidToElectronicVersions < ActiveRecord::Migration[5.0]
  def change
    add_column :electronic_versions, :local_id, :text
  end
end
