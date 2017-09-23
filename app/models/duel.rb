class Duel < ApplicationRecord
  belongs_to :player1, class_name: "User"
  belongs_to :player2, class_name: "User"

  def self.check_if_user_has_been_challenged(user_id)
    where("player2_id = :id AND accepted IS NULL", id: "#{user_id}").where("created_at > ?", 15.minutes.ago).order(:created_at).first
  end

  def self.check_if_any_challenged_user_responded(user_id)
    where("player1_id = :id AND accepted IS NOT NULL AND feedback = false", id: "#{user_id}").order(:created_at).first
  end

  def self.not_allowed(challenged_by, user)
    where("player1_id = :id_1 AND player2_id = :id_2", id_1: "#{challenged_by}", id_2: "#{user}").
      where("created_at > ?", 5.minutes.ago).count > 0
  end
end
