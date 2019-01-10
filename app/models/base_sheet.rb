class BaseSheet < ApplicationRecord
  belongs_to :base_series, foreign_key: 'base_series_abbr'
  belongs_to :region, optional: true #
  has_many :sheets
  #has_many :metadata, through: :sheets

  has_many :copies, through: :sheets

  def build_title

  end
end
