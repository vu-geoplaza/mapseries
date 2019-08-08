class AddGeomToRegions < ActiveRecord::Migration[5.0]
  def change
    add_column :regions, :geom4326, :st_polygon, srid: 4326
  end
end
