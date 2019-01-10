class Shelfmark < ApplicationRecord
  belongs_to :library, foreign_key: 'library_abbr'
  has_many :copies
  belongs_to :bibliographic_metadatum, optional: true, foreign_key: 'oclcnr'
end
