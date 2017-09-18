class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  mount_uploader :image, ImageUploader
  validates :nickname, presence: true, length: { minimum: 3 }, uniqueness: true

  def get_image_url
    self.image.file.size > 0 ? self.image.url : "default_avatar.jpg"
  end
end
