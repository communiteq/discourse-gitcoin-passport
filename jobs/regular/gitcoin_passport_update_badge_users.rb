# frozen_string_literal: true

module Jobs
    class GitcoinPassportUpdateBadgeUsers < ::Jobs::Base
      def execute(args)
        return unless SiteSetting.gitcoin_passport_enabled
  
        raise Discourse::InvalidParameters.new('badge_id') if args[:badge_id].blank?
  
        badge = Badge.find(args[:badge_id])
        DiscourseGitcoinPassport::Helpers.update_users_for_badge(badge) if badge
      end
    end
  end
  