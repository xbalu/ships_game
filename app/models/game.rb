class Game < ApplicationRecord
  SHIPS_NAMES = { "4_ship" => "Aircraft carrier (4 parts)", "3_ship" => "Destroyer (3 parts)",
    "2_ship" => "Cruiser (2 parts)", "1_ship" => "Frigate (1 part)"}

  NEIGHBOURS = [[0, -1], [0, 1], [-1, 0], [1, 0], [-1, -1], [1, -1], [-1, 1], [1, 1]]

  serialize :player1_grid, Hash
  serialize :player2_grid, Hash
  serialize :player1_ships, Hash
  serialize :player2_ships, Hash
  belongs_to :player1, class_name: "User"
  belongs_to :player2, class_name: "User", optional: true

  def include_player?(player_id)
    (self.player1_id == player_id) || (self.player2_id == player_id)
  end

  def ship_key_to_deploy(player_id)
    ships_number = count_deployed_ships(player_id)

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

  def count_deployed_ships(player_id)
    player_ships = self.player1_id == player_id ? self.player1_ships : self.player2_ships
    player_ships.count
  end

  def get_ship_name_by_key(ship_key)
    SHIPS_NAMES.select { |k, v| k[/#{ship_key[0..5]}/] }.values[0]
  end

  def get_game_grids(player_id)
    self.player1_id == player_id ? [self.player1_grid, self.player2_grid] : [self.player2_grid, self.player1_grid]
  end

  def get_misses(player_id)
    self.player1_id == player_id ? [self.player1_misses, self.player2_misses] : [self.player2_misses, self.player1_misses]
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

  def check_clicked_field(attacker, row, col)
    is_enemy_first = self.player1_id != attacker

    if is_enemy_first
      player_grid = self.player1_grid
      player_ships = self.player1_ships
    else
      player_grid = self.player2_grid
      player_ships = self.player2_ships
    end

    message = ""

    if player_grid[[row, col]] == :ship
      player_grid[[row, col]] = :hit

      key = player_ships.select { |k, v| v.include?([row, col]) }.keys[0]
      ship_burned = player_ships[key].all? { |e| player_grid[e] == :hit }

      if ship_burned
        player_grid = mark_ship_neighbours(player_ships[key], player_grid)
        message = "Ship burned!"
      else
        message = "Ship hit"
      end
    else
      player_grid[[row, col]] = :miss
      is_enemy_first ? self.player2_misses += 1 : self.player1_misses += 1
      message = "Miss"
    end

    if is_enemy_first
      self.player1_grid = player_grid
      self.current_player = self.player1_id
    else
      self.player2_grid = player_grid
      self.current_player = self.player2_id
    end

    if all_ships_destroyed(player_grid)
      self.winner_id = attacker
      self.status = "ended"
      message = "Game ended!"
    end

    self.save
    message
  end

  def mark_ship_neighbours(fields, player_grid)
    fields.each do |field|
      NEIGHBOURS.each do |neighbour|
        row = field[0] + neighbour[0]
        col = field[1] + neighbour[1]
        player_grid[[row, col]] = :miss if player_grid[[row, col]] == :empty
      end
    end
    player_grid
  end

  def all_ships_destroyed(player_grid)
    player_grid.select { |k, v| v == :ship }.count == 0
  end
end
