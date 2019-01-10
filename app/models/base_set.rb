class BaseSet < ApplicationRecord
  has_many :sheets
  belongs_to :base_series, foreign_key: 'base_series_abbr'

  has_many :copies, through: :sheets
end
