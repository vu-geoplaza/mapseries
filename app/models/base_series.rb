class BaseSeries < ApplicationRecord
  self.primary_key = 'abbr'

  serialize :metadata_fields, JSON
  serialize :set_metadata_fields, JSON

  has_many :base_sheets, :foreign_key => :base_series_abbr
  has_many :base_sets, :foreign_key => :base_series_abbr
  has_many :sheets, through: :base_sheets
  has_many :metadata, through: :sheets
  has_many :copies, through: :sheets
  has_many :regions, through: :base_sheets
end
