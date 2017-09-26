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
  has_many :comments, dependent: :destroy
  has_one :duel, dependent: :destroy

  self.per_page = 12

  def self.initialize_new_game(player1_id)
    empty_grid = build_empty_grid

    Game.create(status: "pending", current_player: 0, player1_id: player1_id,
      player1_grid: empty_grid, player2_grid: empty_grid, player1_ships: {}, player2_ships: {},
      player1_misses: 0, player2_misses: 0, winner_id: 0)
  end

  def force_player_join(player_id)
    return if status != "pending"

    self.player2_id = player_id
    self.status = "deployment"
    self.save!
  end

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

  def get_ship_parts_by_key(ship_key)
    ship_key[0].to_i
  end

  def get_game_grids(player_id)
    self.player1_id == player_id ? [self.player1_grid, self.player2_grid] : [self.player2_grid, self.player1_grid]
  end

  def get_misses
    [self.player1_misses, self.player2_misses]
  end

  def save_last_attack(player, row, col)
    arr = [row, col]
    self.player1_id == player ? self.player1_last_attack = arr : self.player2_last_attack = arr
    self.save
  end

  def get_last_attacked_field(player)
    self.player1_id == player ? self.player2_last_attack : self.player1_last_attack
  end

  def erase_last_attacked_field(player)
    self.player1_id == player ? self.player2_last_attack = [] : self.player1_last_attack = []
    self.save
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
      self.current_player = rand(2) == 1 ? self.player1.id : self.player2_id
      self.save
    end
  end

  def get_ships_left
    [self.player1_ships.select { |k, v| v != [0] }.count, self.player2_ships.select { |k, v| v != [0] }.count]
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

    return if player_grid[[row, col]] == :miss || player_grid[[row, col]] == :hit ||
      player_grid[[row, col]] == :burned

    message = ""

    if player_grid[[row, col]] == :ship
      player_grid[[row, col]] = :hit

      key = player_ships.select { |k, v| v.include?([row, col]) }.keys[0]
      ship_burned = player_ships[key].all? { |e| player_grid[e] == :hit }

      if ship_burned
        player_grid = burn_enemy_ship(player_ships[key], player_grid)
        message = "Ship burned!"
        player_ships[key] = [0]
      else
        message = "Ship hit"
      end
    else
      player_grid[[row, col]] = :miss
      message = "Miss"

      if is_enemy_first
        self.player2_misses += 1
        self.current_player = self.player1_id
      else
        self.player1_misses += 1
        self.current_player = self.player2_id
      end
    end

    if all_ships_destroyed(player_grid)
      self.winner_id = attacker
      self.status = "ended"
      winner = User.find(attacker)
      looser = is_enemy_first ? User.find(self.player1_id) : User.find(self.player2_id)
      winner.games_won += 1
      looser.games_lost += 1
      winner_current_rank = winner.rank
      looser_current_rank = looser.rank
      winner.rank = calculate_new_rank(winner_current_rank, looser_current_rank, 1)
      looser.rank = calculate_new_rank(looser_current_rank, winner_current_rank, 0)
      winner.save
      looser.save
      message = "Game ended!"
      winner_rank_diff = winner.rank - winner_current_rank
      looser_rank_diff = looser.rank - looser_current_rank
      chat_msg = "<strong>#{winner.nickname} rank: <span style=color:#196719>+#{winner_rank_diff}</span>
        <br>#{looser.nickname} rank: <span style=color:red>#{looser_rank_diff}</span></strong>"
      self.comments.create(nickname: "", message: chat_msg)
    end

    self.save
    message
  end

  def calculate_new_rank(rank1, rank2, won)
    rank_difference = rank2 - rank1
    expected_points = 1 / (1 + 10 ** (rank_difference / 400.0))
    absolute_rank_change = won - expected_points
    (rank1 + (32 * absolute_rank_change)).round
  end

  def self.get_user_games(user)
    where("player1_id = :id OR player2_id = :id", id: "#{user}")
  end

  def self.get_first_pending_game(user)
    where(status: "pending").where.not("player1_id = :id", id: "#{user}").order(created_at: :desc).first
  end

  def burn_enemy_ship(fields, player_grid)
    fields.each do |field|
      NEIGHBOURS.each do |neighbour|
        row = field[0] + neighbour[0]
        col = field[1] + neighbour[1]
        player_grid[[field[0], field[1]]] = :burned
        player_grid[[row, col]] = :miss if player_grid[[row, col]] == :empty
      end
    end
    player_grid
  end

  def all_ships_destroyed(player_grid)
    player_grid.select { |k, v| v == :ship }.count == 0
  end

  def self.build_empty_grid
    grid = {}
    (1..10).each do |x|
      (1..10).each do |y|
        grid[[x, y]] = :empty
      end
    end
    grid
  end

  def self.shutdown_timed_out_games
    games = self.where("status <> 'pending' AND status <> 'ended' AND created_at < ?", 24.hours.ago)
    games.each do |game|
      game.comments.create!(nickname: "", message: "<strong style='color: #990033;'>
        Timed out!<br>The game has ended</strong>")
      game.status = "ended"
      game.save!
    end
  end
end
