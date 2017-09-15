class AddPlayersLastAttackToGames < ActiveRecord::Migration[5.1]
  def change
    add_column :games, :player1_last_attack, :integer, array: true, default: []
    add_column :games, :player2_last_attack, :integer, array: true, default: []
  end
end
