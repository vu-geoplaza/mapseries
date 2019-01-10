class CreateBaseMetadata < ActiveRecord::Migration[5.0]
  def change
    create_table :libraries, id: false do |t|
      t.text :name
      t.string :abbr
      t.timestamps
    end
    add_index :libraries, :abbr, unique: true

    create_table :bibliographic_metadata, id: false do |t|
      t.string :oclcnr
      t.timestamps
    end
    add_index :bibliographic_metadata, :oclcnr, unique: true

    create_table :base_series, id: false do |t|
      t.string :name, null: false, unique: true
      t.string :abbr, null: false, unique: true
      t.text :metadata_fields, null: false
      t.text :set_metadata_fields, null: false
      t.timestamps
    end
    add_index :base_series, :abbr, unique: true

    create_table :regions do |t|
      t.string :name, null: false
      t.text :polygon
      t.st_polygon :geom, srid: 28992
      t.timestamps
    end

    create_table :base_sets do |t|
      t.string :display_title, null: false
      t.string :editie, default: 'NA'
      t.string :serie
      t.string :titel
      t.string :base_series_abbr, index: true
      t.timestamps
    end
    add_foreign_key :base_sets, :base_series, primary_key: :abbr, column: 'base_series_abbr'

    create_table :base_sheets do |t|
      t.string :title, null: false
      t.belongs_to :region, foreign_key: true
      t.string :base_series_abbr, index: true
      t.timestamps
    end
    add_foreign_key :base_sheets, :base_series, primary_key: :abbr, column: 'base_series_abbr'

=begin
    create_table :publishers do |t|
      t.string :name
      t.string :place
      t.string :description
      t.timestamps
    end
=end

    create_table :sheets do |t|
      # general fields
      t.date :pubdate
      t.boolean :pubdate_exact, default: true
      t.string :edition, default: 'NA'
      t.integer :is_based_on # is the sheet based on another map sheet? For example json_nationaal_archief sheets were based on TMK, and there were quarter and half tmk sheets
      t.belongs_to :base_sheet, index: true, foreign_key: true
      t.belongs_to :base_set, index: true, foreign_key: true
      t.string :titel
      t.string :display_title

      # specific fields
      t.string :nummer
      t.string :uitgever
      t.string :verkend
      t.string :herzien
      t.string :bewerkt
      t.string :uitgave
      t.string :bijgewerkt
      t.string :opname_jaar
      t.string :basis_jaar
      t.string :basis
      t.string :schaal
      t.string :bewerker
      t.string :reproductie
      t.string :editie
      t.boolean :waterstaatskaart
      t.boolean :bijkaart_we
      t.boolean :bijkaart_hw
      t.text :opmerkingen
      t.timestamps
    end

    #add_foreign_key :sheets, :sheets, primary_key: :id, column: 'is_based_on'

    create_table :shelfmarks do |t|
      t.string :shelfmark
      t.string :library_abbr, index: true
      t.string :oclcnr, index: true
      t.timestamps
    end
    add_foreign_key :shelfmarks, :libraries, primary_key: :abbr, column: 'library_abbr'
    add_foreign_key :shelfmarks, :bibliographic_metadata, primary_key: :oclcnr, column: 'oclcnr'

    create_table :provenances do |t|
      t.string :name
      t.text :description
      t.string :library_abbr, index: true
      t.timestamps
    end
    add_foreign_key :provenances, :libraries, primary_key: :abbr, column: 'library_abbr'

    create_table :copies do |t|
      t.text :phys_char
      t.text :description
      t.text :stamps
      t.text :csv_row
      t.belongs_to :sheet, index: true, foreign_key: true
      t.belongs_to :provenance, index: true, foreign_key: true
      t.belongs_to :shelfmark, index: true, foreign_key: true
      t.timestamps
    end

    create_table :repositories do |t|
      t.string :name
      t.string :base_url
      t.text :description
      t.string :library_abbr, index: true
      t.timestamps
    end
    add_foreign_key :repositories, :libraries, primary_key: :abbr, column: 'library_abbr'

    create_table :ogc_web_services do |t|
      t.string :url
      t.string :services
      t.string :viewer_url
      t.timestamps
    end

    create_table :electronic_versions do |t|
      t.string :repository_url
      t.string :service_type

      t.belongs_to :ogc_web_service, index: true, foreign_key: true
      t.belongs_to :repository, index: true, foreign_key: true
      t.belongs_to :copy, index: true, foreign_key: true
      t.timestamps
    end
  end
end
