class UsersController < ApplicationController
  before_action :authenticate_user!

  def profile
    user_id = params[:id].to_i
    @user = User.find(user_id)
    @user_games = Game.get_user_games(user_id).order(created_at: :desc)
    @games = @user_games.paginate(:page => params[:page], :per_page => 5)
    @games_ended_count = @user_games.where(status: "ended").count
    @games_won = @user.games_won
    @games_lost = @user.games_lost
  end

  def show_all
    @users = User.get_nickname_ilike(params["user_name"]).order(rank: :desc, id: :asc).
      paginate(:page => params[:page], :per_page => 20)
    @users = @users.get_online_users if params[:online] == "true"

    @ranks_order = User.order(rank: :desc, id: :asc).pluck(:id)
  end
end
