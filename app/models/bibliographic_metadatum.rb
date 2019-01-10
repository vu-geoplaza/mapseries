class BibliographicMetadatum < ApplicationRecord
  self.primary_key = 'oclcnr'
  has_many :shelfmarks, :foreign_key => :oclcnr
end
