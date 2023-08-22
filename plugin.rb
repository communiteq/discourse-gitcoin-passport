# name: discourse-gitcoin-passport
# about: Communiteq Gitcoin Passport plugin
# version: 1.0.2
# authors: richard@communiteq.com
# url: https://github.com/communiteq/discourse-gitcoin-passport

enabled_site_setting :gitcoin_passport_enabled

module ::DiscourseGitcoinPassport
  PLUGIN_NAME = "discourse-gitcoin-passport"
end

require_relative "lib/discourse_gitcoin_passport/engine"

after_initialize do
  require_relative "lib/discourse_gitcoin_passport/helpers"
  require_relative "lib/discourse_gitcoin_passport/api_client.rb"
  require_relative "jobs/regular/gitcoin_passport_get_score.rb"
  require_relative "jobs/regular/gitcoin_passport_update_badge_users.rb"
  require_relative "jobs/regular/gitcoin_passport_update_group_membership.rb"
  require_relative "jobs/scheduled/gitcoin_passport_update_all.rb"

  SeedFu.fixture_paths << File.dirname(__FILE__) + "/db/fixtures"

  unless Object.const_defined?("Eth::Ens::Resolver")
    AdminDashboardData.add_problem_check do
      "The discourse-gitcoin-passport plugin depends on the discourse-siwe-auth " +
      "plugin version 0.1.2 or higher for ENS name resolution and authentication, " +
      "however it does not seem to be installed."
    end
  end

  class ::User
    def gitcoin_passport_status
      eth_account = self.associated_accounts.find { |aa| aa[:name] == "siwe" }
      if eth_account
        if self.custom_fields[:unique_humanity_score]
          return 3 # siwe account and passport score present
        else
          return 2 # siwe account connected, no UH score
        end
      else
        return 1 # no siwe account connected
      end
    end

    def unique_humanity_score
      self.custom_fields[:unique_humanity_score].to_f
    end

    def refresh_unique_humanity_score
      return unless SiteSetting.gitcoin_passport_enabled && self.gitcoin_passport_status > 1
      
      args = { user_id: self.id }
      Jobs.enqueue(:gitcoin_passport_get_score, args)
    end

    def set_unique_humanity_score(score)
      # we save the score with leading digits as 000.000 so we can easily compare strings in SQL
      fmt_score = sprintf('%07.3f', score)
      if self.custom_fields[:unique_humanity_score] != fmt_score
        self.custom_fields[:unique_humanity_score] = fmt_score
        self.save_custom_fields
        DiscourseGitcoinPassport::Helpers.update_groups_for_user(self)
        DiscourseGitcoinPassport::Helpers.update_badges_for_user(self)
      end
      score
    end
  end

  %i[current_user basic_user admin_detailed_user].each do |s|
    add_to_serializer(s, :gitcoin_passport_status) {
      object.gitcoin_passport_status
    }

    add_to_serializer(s, :unique_humanity_score?) do
      object.custom_fields[:unique_humanity_score].to_f || 0
    end
  end

  # destroy passport on removal of SIWE account
  add_model_callback(UserAssociatedAccount, :before_destroy) do
    if self.provider_name = "siwe"
      self.user.set_unique_humanity_score(0)
      self.user.custom_fields.delete(:unique_humanity_score)
      self.user.save_custom_fields
    end
  end

  # refresh screen on connect of SIWE account
  add_model_callback(UserAssociatedAccount, :after_commit, on: :create) do
    if self.provider_name = "siwe"
      MessageBus.publish("/file-change", ["refresh"], user_ids: [ self.user.id ])
    end
  end

  def initialize_gitcoin_passport_plugin
    DiscourseGitcoinPassport::Helpers.change_automatic_groups
    group_id = BadgeGrouping.find_by(name: SiteSetting.gitcoin_passport_badge_group)&.id
    if group_id
      Badge.where(badge_grouping_id: group_id).pluck(:id).each do |badge_id|
        args = { badge_id: badge_id }
        Jobs.enqueue(:gitcoin_passport_update_badge_users, args)
      end
    end
  end

  DiscourseEvent.on(:site_setting_changed) do |name, old_value, new_value|
    if [:gitcoin_passport_enabled].include? name
      initialize_gitcoin_passport_plugin
    end

    if [:gitcoin_passport_group_levels].include? name
      DiscourseGitcoinPassport::Helpers.change_automatic_groups
    end

    if [:gitcoin_passport_badge_group].include? name
      bg = BadgeGrouping.where(name: old_value).first
      if bg
        bg.name = new_value
        bg.save
      end
    end

    if [
        :gitcoin_passport_badge_bronze_score,
        :gitcoin_passport_badge_silver_score,
        :gitcoin_passport_badge_gold_score
      ].include? name
      group_id = BadgeGrouping.where(name: SiteSetting.gitcoin_passport_badge_group).first&.id
      type_id = DiscourseGitcoinPassport::Helpers.get_badge_type(name)
      if group_id && type_id
        badge = Badge.find_by(badge_grouping_id: group_id, badge_type_id: type_id)
        if badge
          badge.description = "Has a unique humanity score of at least #{new_value}"
          badge.save
          args = { badge_id: badge.id }
          Jobs.enqueue(:gitcoin_passport_update_badge_users, args)
        end
      end
    end
  end

  # initialize correctly
  if Discourse.running_in_rack?
    RailsMultisite::ConnectionManagement.each_connection do |db_name|
      initialize_gitcoin_passport_plugin if SiteSetting.gitcoin_passport_enabled
    end
  end
end