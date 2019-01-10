class Region < ApplicationRecord
  serialize :bbox, JSON

  has_many :base_sheets
end
