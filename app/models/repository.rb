class Repository < ApplicationRecord
  belongs_to :library
  has_many :electronic_versions
end
