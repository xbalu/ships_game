class Game < ApplicationRecord
  SHIPS_NAMES = { "4_ship" => "Aircraft (4 parts)", "3_ship" => "Destroyer (3 parts)",
    "2_ship" => "Cruiser (2 parts)", "1_ship" => "Frigate (1 part)"}

  NEIGHBOURS = [[0, -1], [0, 1], [-1, 0], [1, 0], [-1, -1], [1, -1], [-1, 1], [1, 1]]

  serialize :player1_grid, Hash
  serialize :player2_grid, Hash
  serialize :player1_ships, Hash
  serialize :player2_ships, Hash
  belongs_to :player1, class_name: "User"
  belongs_to :player2, class_name: "User", optional: true

  def ship_key_to_deploy(player_id)
    player_ships = self.player1_id == player_id ? self.player1_ships : self.player2_ships
    ships_number = player_ships.count

    case ships_number
    when 0
      "4_ship_1"
    when 1..2
      "3_ship_#{ships_number + 1}"
    when 3..5
      "2_ship_#{ships_number + 1}"
    when 6..9
      "1_ship_#{ships_number + 1}"
    when 10
      :ships_deployed
    end
  end

  def get_ship_name_by_key(ship_key)
    SHIPS_NAMES.select { |k, v| k[/#{ship_key[0..5]}/] }.values[0]
  end

  def ship_deploy(player, row, col, dir, ship_key)
    is_first_player = self.player1_id == player
    player_grid = is_first_player ? self.player1_grid : self.player2_grid

    case dir
    when "up"
      rowmod, colmod = -1, 0
    when "right"
      rowmod, colmod = 0, 1
    when "down"
      rowmod, colmod = 1, 0
    when "left"
      rowmod, colmod = 0, -1
    end

    ship_fields = []
    ship_length = ship_key[0].to_i

    (ship_length).times do |i|
      new_row, new_col = row + rowmod * i, col + colmod * i
      ship_fields << [new_row, new_col]

      if player_grid[[new_row, new_col]] != :empty || !(1..10).include?(new_row) ||
        !(1..10).include?(new_col) || any_ship_around(player_grid, new_row, new_col) == true

        return false
      end
    end

    if is_first_player
      self.player1_ships[ship_key] = ship_fields
      ship_fields.each { |field| self.player1_grid[field] = :ship }
    else
      self.player2_ships[ship_key] = ship_fields
      ship_fields.each { |field| self.player2_grid[field] = :ship }
    end
    self.save

    true
  end

  def any_ship_around(grid, row, col)
    NEIGHBOURS.length.times do |i|
        return true if grid[[row + NEIGHBOURS[i][0], col + NEIGHBOURS[i][1]]] == :ship
    end

    false
  end

  def check_start_condition
    if self.ship_key_to_deploy(self.player1_id) == :ships_deployed &&
      self.ship_key_to_deploy(self.player2_id) == :ships_deployed

      self.status = "started"
      self.save
    end
  end
end
