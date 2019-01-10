class ElectronicVersion < ApplicationRecord
  belongs_to :copy
  belongs_to :repository
  belongs_to :ogc_web_service, optional: true
end

