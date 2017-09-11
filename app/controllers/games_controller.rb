class GamesController < ApplicationController
  before_action :authenticate_user!

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

    case game.status
    when "pending"
      render json: { status: game.status }
    when "deployment", "started"
      if game.player1_id == player
        player_grid = game.player1_grid
        player_ships = game.player1_ships
      else
        player_grid = game.player2_grid
        player_ships = game.player2_ships
      end

      ship_key = game.ship_key_to_deploy(player)
      next_ship_name = game.get_ship_name_by_key(ship_key)

      render json: { status: game.status, player_grid: player_grid, next_ship_name: next_ship_name,
        ships_count: player_ships.count }
    end
  end

  def send_data
    game = Game.find(params[:id])
    player = current_user.id

    if game.status == "deployment"
      row = params[:row].to_i
      col = params[:col].to_i
      dir = params[:direction]
      ship_key = game.ship_key_to_deploy(player)

      unless ship_key == :ships_deployed
        return_value = game.ship_deploy(player, row, col, dir, ship_key)

        if game.player1_id == player
          player_grid = game.player1_grid
          player_ships = game.player1_ships
        else
          player_grid = game.player2_grid
          player_ships = game.player2_ships
        end

        render json: { return_value: return_value, player_grid: player_grid,
          ships_count: player_ships.count }
      end

      game.check_start_condition
    end
  end

  private

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
