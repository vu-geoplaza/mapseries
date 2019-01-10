class Copy < ApplicationRecord
  belongs_to :sheet
  belongs_to :provenance
  belongs_to :shelfmark
  has_many :electronic_versions

  validates :sheet_id, :presence => true

  # Sunspot fields
=begin
  searchable do
    text :phys_char, :description, :stamps

    text :sheet_titel do
      sheet.titel
    end
    text :nummer do
      sheet.nummer
    end

    date :pubdate do
      sheet.pubdate
    end

    text :uitgever do
      sheet.uitgever
    end
    text :bewerker do
      sheet.bewerker
    end
    text :reproductie do
      sheet.reproductie
    end

    text :shelfmark do
      shelfmark.shelfmark
    end

    # facet fields
    string :base_set do
      sheet.base_set.display_title
    end
    string :library do
      shelfmark.library.name
    end
    string :repositories, :multiple => true do
      electronic_versions.map { |ev|  ev.repository.name }
    end
  end
=end
end
