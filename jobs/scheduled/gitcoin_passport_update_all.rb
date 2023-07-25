# frozen_string_literal: true

module Jobs
  class GitcoinPassportUpdateAll < Jobs::Scheduled
    every 24.hours

    def execute(_args)
      return unless SiteSetting.gitcoin_passport_enabled

      DiscourseGitcoinPassport::Helpers.update_all_passport_scores
    end
  end
end
    