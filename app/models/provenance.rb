class Provenance < ApplicationRecord
  belongs_to :library, foreign_key: 'library_abbr'
  has_many :copies
end