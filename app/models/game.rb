class Game < ApplicationRecord
  serialize :player1_grid, Hash
  serialize :player2_grid, Hash
  serialize :player1_ships, Hash
  serialize :player2_ships, Hash
  belongs_to :player1, class_name: "User"
  belongs_to :player2, class_name: "User", optional: true
end
