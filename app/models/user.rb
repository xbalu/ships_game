class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :lastseenable

  mount_uploader :image, ImageUploader
  validates :nickname, presence: true, length: { minimum: 3, maximum: 12 }, uniqueness: true

  def get_image_url
    self.image.file.size > 0 ? self.image.url : 'default_avatar.jpg'
  end

  def is_admin?
    self.admin_flag
  end

  def online?
    last_seen && last_seen > 5.minutes.ago ? true : false
  end

  def self.get_online_users
    where("last_seen > ?", 5.minutes.ago)
  end

  def self.get_nickname_ilike(phrase)
    where("nickname ILIKE :param", param: "%#{phrase}%")
  end
end
