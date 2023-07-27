# name: discourse-gitcoin-passport
# about: Communiteq Gitcoin Passport plugin
# version: 1.0
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
  require_relative "jobs/regular/gitcoin_passport_update_group_membership.rb"
  require_relative "jobs/scheduled/gitcoin_passport_update_all.rb"

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
      # we save the score with leading digits as 000.00 so we can easily compare strings in SQL
      fmt_score = sprintf('%06.2f', score)
      if self.custom_fields[:unique_humanity_score] != fmt_score
        self.custom_fields[:unique_humanity_score] = fmt_score
        self.save_custom_fields
        DiscourseGitcoinPassport::Helpers.update_groups_for_user(self)
      end
    end
  end

  %i[current_user admin_detailed_user].each do |s|
    add_to_serializer(s, :gitcoin_passport_status) {
      object.gitcoin_passport_status
    }

    add_to_serializer(s, :include_gitcoin_passport_status?) do
      SiteSetting.gitcoin_passport_enabled
    end

    add_to_serializer(s, :unique_humanity_score?) do
      object.custom_fields[:unique_humanity_score].to_f || 0
    end

    add_to_serializer(s, :include_unique_humanity_score?) do
      SiteSetting.gitcoin_passport_enabled
    end
  end

  DiscourseEvent.on(:site_setting_changed) do |name, old_value, new_value|
    if [:gitcoin_passport_group_levels].include? name
      levels = new_value.split(',').map(&:to_i).select { |num| (0..100).include?(num) }
      DiscourseGitcoinPassport::Helpers.change_automatic_groups(levels)
    end
  end

end