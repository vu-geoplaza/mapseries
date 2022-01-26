class AddDziToElectronicVersions < ActiveRecord::Migration[5.0]
  def change
    add_column :electronic_versions, :dzi, :text
  end
end
