class AddTmkfieldsToSheets < ActiveRecord::Migration[5.0]
  def change
    ##Editievermelding,Stempel,verkend,gegraveerd,herzien,ged.herzien,omgewerkt,bijgewerkt,uitgave
    add_column :sheets, :stempel, :text
    add_column :sheets, :gegraveerd, :text
    add_column :sheets, :ged_herzien, :text
    add_column :sheets, :omgewerkt, :text
  end
end
