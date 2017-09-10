class CreateGames < ActiveRecord::Migration[5.1]
  def change
    create_table :games do |t|
      t.string :status
      t.integer :current_player
      t.integer :player1_id
      t.integer :player2_id
      t.text :player1_grid
      t.text :player2_grid
      t.text :player1_ships
      t.text :player2_ships
      t.integer :player1_misses
      t.integer :player2_misses
      t.integer :winner_id

      t.timestamps
    end

    add_foreign_key :games, :users, column: :player1_id
    add_foreign_key :games, :users, column: :player2_id
  end
end
