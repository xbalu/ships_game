class CreateDuels < ActiveRecord::Migration[5.1]
  def change
    create_table :duels do |t|
      t.integer :player1_id, index: true
      t.integer :player2_id, index: true
      t.boolean :accepted
      t.integer :game_id
      t.boolean :feedback, default: false

      t.timestamps
    end

    add_foreign_key :duels, :users, column: :player1_id
    add_foreign_key :duels, :users, column: :player2_id
    add_foreign_key :duels, :games, column: :game_id
  end
end
