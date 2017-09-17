class GamesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_if_user_belongs_to_game, only: [:show, :send_data_to_js, :get_data_from_js]

  def check_if_user_belongs_to_game
    game = Game.find(params[:id])
    player = current_user.id

    if !game.include_player?(player)
      flash[:alert] = "You don\'t have permission to do that"
      redirect_to root_url
    end
  end

  def index
    @status_color = { "pending" => "#009900", "deployment" => "#001866",
      "started" => "#001866", "ended" => "#ff1a1a" }
    query = params[:pending] == "true" ? "status = \'pending\'" : ""
    @games = Game.all.where(query).order(created_at: :desc).paginate(:page => params[:page], :per_page => 12)
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
    @player1_name = User.find(@game.player1_id).nickname
  end

  def send_data_to_js
    game = Game.find(params[:id])
    player = current_user.id
    player2 = game.player2_id
    player2_name = player2 ? User.find_by(id: player2).nickname : ""
    status = game.status
    status_params = {}
    player_grid, enemy_grid = game.get_game_grids(player)
    comments = game.comments.order(created_at: :desc)

    case status
    when "deployment"
      next_ship_name = game.get_ship_name_by_key(game.ship_key_to_deploy(player))
      ships_deployed = game.count_deployed_ships(player)
      status_params["deployment"] = { next_ship_name: next_ship_name, ships_deployed: ships_deployed }
    when "started"
      allow_move = game.current_player == player
      current_player_name = User.find(game.current_player).nickname
      last_attacked_field = game.get_last_attacked_field(player)
      game.erase_last_attacked_field(player)
      status_params["started"] = { allow_move: allow_move, current_player_name: current_player_name,
        attacked_field: last_attacked_field }
    when "ended"
      winner_name = User.find(game.winner_id).nickname
      status_params["ended"] = { winner_name: winner_name }
    end

    render json: { status: status, player2_name: player2_name, player_grid: player_grid,
      enemy_grid: status != "ended" ? hide_ships(enemy_grid) : enemy_grid, status_params: status_params,
      misses: game.get_misses, ships_left: game.get_ships_left, comments: comments }
  end

  def get_data_from_js
    game = Game.find(params[:id])
    player = current_user.id

    if params[:comment]
      save_user_comment(game.id, player, params[:comment])
      return
    end

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

      render json: { return_value: return_value, ship_parts: game.get_ship_parts_by_key(ship_key),
        player_grid: player_grid, ships_deployed: ships_deployed, status: game.status }
    when "started"
      message = game.check_clicked_field(player, row, col)
      game.save_last_attack(player, row, col)
      render json: { message: message }
    end
  end

  def save_user_comment(game_id, user, message)
    nickname = User.find(user).nickname
    Comment.create(game_id: game_id, user_id: user, nickname: nickname, message: message)
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
