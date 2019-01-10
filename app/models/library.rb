class Library < ApplicationRecord
  self.primary_key = 'abbr'
  has_many :provenances, foreign_key: :library_abbr
  has_many :shelfmarks, foreign_key: :library_abbr
  has_many :repositories, foreign_key: :library_abbr

  has_many :copies, through: :shelfmarks

  has_and_belongs_to_many :users, foreign_key: :library_abbr
end
