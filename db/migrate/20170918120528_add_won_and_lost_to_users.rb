class AddWonAndLostToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :games_won, :integer, default: 0
    add_column :users, :games_lost, :integer, default: 0
  end
end
