class DuelsController < ApplicationController
  before_action :authenticate_user!, only: [:challenge]

  def find_new
    return if !user_signed_in?

    user_id = current_user.id
    duel = Duel.check_if_user_has_been_challenged(user_id)
    duel_response = Duel.check_if_any_challenged_user_responded(user_id)
    params = {}

    if duel
      player1 = User.find(duel.player1_id)
      invited_by = player1.nickname + " [#{player1.rank}]"
      params[:duel_id] = duel.id
      params[:invited_by] = invited_by
    end

    if duel_response
      duel_response.feedback = true;
      duel_response.save!
      player2 = User.find(duel_response.player2_id)
      params[:response_from] = player2.nickname + " [#{player2.rank}]"
      params[:game_url] = duel_response.accepted ? game_url(duel_response.game_id) : ""
      params[:created_at] = duel_response.created_at.to_s[0..15].insert(10, ' -')
    end

    render json: params
  end

  def user_response
    duel = Duel.find(params[:duel_id])
    return if !duel.accepted.nil?

    accepted = params[:accepted]
    duel.accepted = accepted

    if accepted == "true"
      game = Game.initialize_new_game(duel.player1_id)
      duel.game_id = game.id
      game.force_player_join(duel.player2_id)
      url = game_url(game)
    else
      url = ""
    end

    duel.save!
    render json: { game_url: url }
  end

  def challenge
    challenged_by = current_user.id
    user_id = params[:id].to_i

    if !User.find(user_id).online?
      flash[:error] = "You can't challenge offline user"
    elsif Duel.not_allowed(challenged_by, user_id)
      flash[:error] = "You can challenge the same user only once per 5 minutes"
    elsif Duel.challenged_recently?(user_id)
      flash[:error] = "The user has been just challenged by someone, let him take a breath"
    elsif challenged_by != user_id
      Duel.create!(player1_id: challenged_by, player2_id: user_id)
      flash[:notice] = "Duel challenge has been sent"
    end

    redirect_back(fallback_location: users_path)
  end
end
