# frozen_string_literal: true

module DiscourseGitcoinPassport
  class ScoreController < ApplicationController
    requires_plugin DiscourseGitcoinPassport::PLUGIN_NAME
    requires_login
    before_action :ensure_logged_in

    def refresh
      if current_user.admin? && params[:user_id].present?
        user = User.find(params[:user_id])
      else
        user = current_user
      end
      DiscourseGitcoinPassport::Helpers.update_passport_score_for_user(user)
      render json: {
        unique_humanity_score: user.unique_humanity_score
      }
    end
  end
end
