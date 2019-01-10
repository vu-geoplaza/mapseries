class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  has_and_belongs_to_many :libraries, association_foreign_key: 'library_abbr'

  # user: no special privileges
  # editor: can edit copies from own libraries
  # admin: can edit everything
  enum role: {user: 0, editor: 1, admin: 2}
end
