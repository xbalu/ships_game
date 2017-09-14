class GamesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_if_user_belongs_to_game, only: [:show, :get_data, :send_data]

  def check_if_user_belongs_to_game
    game = Game.find(params[:id])
    player = current_user.id

    if !game.include_player?(player)
      flash[:alert] = "You don\'t have permission to do that"
      redirect_to root_url
    end
  end

  def index
    @games = Game.all.order(created_at: :desc)
  end

  def new
    player1_id = current_user.id
    empty_grid = build_empty_grid

    game = Game.create(status: "pending", current_player: player1_id, player1_id: player1_id,
      player1_grid: empty_grid, player2_grid: empty_grid, player1_ships: {}, player2_ships: {},
      player1_misses: 0, player2_misses: 0, winner_id: 0)

    redirect_to game_url(game)
  end

  def join
    game = Game.find(params[:id])
    game.player2_id = current_user.id
    game.status = "deployment"
    game.save

    redirect_to game_url(game)
  end

  def show
    @game = Game.find(params[:id])
  end

  def get_data
    game = Game.find(params[:id])
    player = current_user.id
    status = game.status
    status_params = {}
    player_grid, enemy_grid = game.get_game_grids(player)

    case status
    when "deployment"
      next_ship_name = game.get_ship_name_by_key(game.ship_key_to_deploy(player))
      ships_deployed = game.count_deployed_ships(player)
      status_params["deployment"] = { next_ship_name: next_ship_name, ships_deployed: ships_deployed }
    when "started"
      allow_move = game.current_player == player
      current_player_name = User.find(game.current_player).nickname
      status_params["started"] = { allow_move: allow_move, current_player_name: current_player_name }
    when "ended"
      winner_name = User.find(game.winner_id).nickname
      status_params["ended"] = { winner_name: winner_name }
    end

    render json: { status: status, player_grid: player_grid, enemy_grid: hide_ships(enemy_grid),
      status_params: status_params, misses: game.get_misses(player) }
  end

  def send_data
    game = Game.find(params[:id])
    player = current_user.id
    row = params[:row].to_i
    col = params[:col].to_i

    case game.status
    when "deployment"
      dir = params[:direction]
      ship_key = game.ship_key_to_deploy(player)
      return_value = game.ship_deploy(player, row, col, dir, ship_key)
      player_grid = game.player1_id == player ? game.player1_grid : game.player2_grid
      ships_deployed = game.count_deployed_ships(player)
      game.check_start_condition

      render json: { return_value: return_value, player_grid: player_grid,
        ships_deployed: ships_deployed, status: game.status }
    when "started"
      message = game.check_clicked_field(player, row, col)
      render json: { message: message }
    end
  end

  private

  def hide_ships(enemy_grid)
    keys = enemy_grid.select { |k, v| v == :ship }.keys
    keys.each { |key| enemy_grid[key] = :empty }
    enemy_grid
  end

  def build_empty_grid
    grid = {}
    (1..10).each do |x|
      (1..10).each do |y|
        grid[[x, y]] = :empty
      end
    end
    grid
  end
end
