class OgcWebService < ApplicationRecord
  serialize :services, JSON

  has_many :electronic_versions
end
