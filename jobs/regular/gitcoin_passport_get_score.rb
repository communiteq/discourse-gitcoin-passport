# frozen_string_literal: true

module Jobs
  class GitcoinPassportGetScore < ::Jobs::Base
    def execute(args)
      return unless SiteSetting.gitcoin_passport_enabled

      raise Discourse::InvalidParameters.new('user_id') if args[:user_id].blank?

      user = User.find(args[:user_id])
      DiscourseGitcoinPassport::Helpers.update_passport_score_for_user(user) if user
    end
  end
end

  