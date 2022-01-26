class AddIiifidToElectronicVersions < ActiveRecord::Migration[5.0]
  def change
    add_column :electronic_versions, :iiif_id, :text
  end
end
