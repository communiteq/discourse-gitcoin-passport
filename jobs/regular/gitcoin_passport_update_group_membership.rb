# frozen_string_literal: true

module Jobs
    class GitcoinPassportUpdateGroupMembership < ::Jobs::Base
      def execute(args)
        return unless SiteSetting.gitcoin_passport_enabled
        DiscourseGitcoinPassport::Helpers.update_users_for_all_groups
      end
    end
  end