# name: discourse-gitcoin-passport
# about: Communiteq Gitcoin Passport plugin
# version: 1.0
# authors: richard@communiteq.com
# url: https://github.com/communiteq/discourse-gitcoin-passport

enabled_site_setting :gitcoin_passport_enabled

after_initialize do

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
  end

  def refresh_unique_humanity_score
    return unless SiteSetting.gitcoin_passport_enabled && self.gitcoin_passport_status > 1

    # implement
  end

  %i[current_user admin_detailed_user].each do |s|
    add_to_serializer(s, :gitcoin_passport_status) {
      object.gitcoin_passport_status
    }

    add_to_serializer(s, :include_gitcoin_passport_status?) do
      SiteSetting.gitcoin_passport_enabled
    end

    add_to_serializer(s, :unique_humanity_score?) do
      object.custom_fields[:unique_humanity_score] || 0
    end

    add_to_serializer(s, :include_unique_humanity_score?) do
      SiteSetting.gitcoin_passport_enabled
    end
  end


end