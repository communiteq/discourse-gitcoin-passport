# frozen_string_literal: true

module DiscourseGitcoinPassport
  class ScoreController < ApplicationController
    requires_plugin DiscourseGitcoinPassport::PLUGIN_NAME
    requires_login
    before_action :ensure_logged_in

    def refresh
      DiscourseGitcoinPassport::Helpers.update_passport_score_for_user(current_user)
      render json: {
        unique_humanity_score: current_user.unique_humanity_score
      }
    end
  end
end
