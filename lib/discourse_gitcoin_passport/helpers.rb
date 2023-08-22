# frozen_string_literal: true

begin
  require 'eth'
rescue LoadError
  # ignore
end

module DiscourseGitcoinPassport
  module Helpers

    def self.eth_client
      @eth_client ||= ::Eth::Client.create(SiteSetting.gitcoin_passport_ethereum_node_url)
    end

    def self.ens_resolver
      @ens_resolver ||= ::Eth::Ens::Resolver.new(self.eth_client)
    end

    def self.gitcoin_api_client
      @gitcoin_client ||= DiscourseGitcoinPassport::ApiClient.new(SiteSetting.gitcoin_passport_api_key, SiteSetting.gitcoin_passport_scorer_id)
    end

    # should be called async
    def self.update_all_passport_scores
      user_ids = UserAssociatedAccount.where(provider_name: "siwe").pluck(:user_id)
      User.where(id: user_ids).each do |user|
        self.update_passport_score_for_user(user)
      end
    end

    # should be called async
    def self.update_passport_score_for_user(user)
      eth_account = user.associated_accounts.find { |aa| aa[:name] == "siwe" }
      if eth_account
        eth_address = eth_account[:description]
        if eth_address && eth_address.ends_with?(".eth") && Object.const_defined?("Eth::Ens::Resolver")
          eth_address = self.ens_resolver.resolve(eth_address)
        end
        api_client = DiscourseGitcoinPassport::ApiClient.new(SiteSetting.gitcoin_passport_api_key, SiteSetting.gitcoin_passport_scorer_id)
        result = self.gitcoin_api_client.submit_passport(eth_address)
        if (result["status"] == "DONE") && (result['score'].to_f >= 0)
          user.set_unique_humanity_score(result['score'].to_f)
        end
      else
        user.set_unique_humanity_score(0)
      end
    end

    def self.change_automatic_groups
      levels = SiteSetting.gitcoin_passport_group_levels.split(',').map(&:to_i).select { |num| (0..100).include?(num) }
      current_groups = Group.where("name LIKE ?", "unique_humanity_%")

      current_levels = current_groups.map { |group| group[:name][/unique_humanity_(\d+)/, 1] }.compact.map(&:to_i).uniq

      remove_levels = current_levels - levels
      Group.where(name: remove_levels.map { |level| "unique_humanity_#{level}" }).destroy_all

      add_levels = levels - current_levels
      add_levels.each do |level|
        # we use automatic: true. 
        # The group is not in AUTO_GROUPS so it will not be managed by Group.refresh_automatic_groups
        # but automatic: true prevents the "membership" tab from being shown in the admin
        Group.create(name: "unique_humanity_#{level}", automatic: true)
      end

      if (remove_levels.count + add_levels.count) > 0
        Jobs.enqueue(:gitcoin_passport_update_group_membership)
        return true
      end
      false
    end

    def self.update_groups_for_user(user)
      score = user.unique_humanity_score
      groups = Group.where("name LIKE ?", "unique_humanity_%")
      groups.each do |group|
        level = group.name[/unique_humanity_(\d+)/,1].to_i
        if level <= score
          group.add(user, automatic: true)
        else
          group.remove(user)
        end
      end
    end

    def self.get_badge_type(str)
      case str
      when /_bronze_/
        BadgeType::Bronze
      when /_silver_/
        BadgeType::Silver
      when /_gold_/
        BadgeType::Gold
      else
        nil
      end
    end

    def self.get_badge_score_for_type(badge_type)
      case badge_type
      when BadgeType::Bronze
        SiteSetting.gitcoin_passport_badge_bronze_score
      when BadgeType::Silver
        SiteSetting.gitcoin_passport_badge_silver_score
      when BadgeType::Gold
        SiteSetting.gitcoin_passport_badge_gold_score
      else
        nil # or raise an error if you prefer
      end
    end

    def self.update_badges_for_user(user)
      score = user.unique_humanity_score
      badge_group = BadgeGrouping.find_by(name: SiteSetting.gitcoin_passport_badge_group)
      if badge_group
        Badge.where(badge_grouping_id: badge_group.id).each do |badge|
          min_score = self.get_badge_score_for_type(badge.badge_type_id)
          if score >= min_score
            BadgeGranter.grant(badge, user)
          else
            user_badge = UserBadge.find_by(badge_id: badge.id, user_id: user.id)
            if user_badge
              BadgeGranter.revoke(user_badge)
            end
          end
        end
      end
    end

    def self.update_users_for_badge(badge)
      min_score = self.get_badge_score_for_type(badge.badge_type_id)
      formatted_min_score = sprintf('%07.3f', min_score)
      current_user_ids = UserBadge.where(badge_id: badge.id).pluck(:user_id)
      qualifying_user_ids = UserCustomField.where(name: 'unique_humanity_score').where("value >= '#{formatted_min_score}'").pluck(:user_id)

      ids_to_add = qualifying_user_ids - current_user_ids
      User.where(id: ids_to_add).each do |user|
        BadgeGranter.grant(badge, user)
      end

      ids_to_remove = current_user_ids - qualifying_user_ids
      ids_to_remove.each do |user_id|
        user_badge = UserBadge.find_by(badge_id: badge.id, user_id: user_id)
        if user_badge
          BadgeGranter.revoke(user_badge)
        end
      end
    end

    def self.update_users_for_group(group)
      level = group.name[/unique_humanity_(\d+)/,1].to_i
      formatted_level = sprintf('%07.3f', level)
      current_user_ids = group.users.pluck(:id)
      qualifying_user_ids = UserCustomField.where(name: 'unique_humanity_score').where("value >= '#{formatted_level}'").pluck(:user_id)

      ids_to_add = qualifying_user_ids - current_user_ids
      User.where(id: ids_to_add).each do |user|
        group.add(user, automatic: true)
      end

      ids_to_remove = current_user_ids - qualifying_user_ids
      User.where(id: ids_to_remove).each do |user|
        group.remove(user)
      end
    end

    def self.update_users_for_all_groups
      groups = Group.where("name LIKE ?", "unique_humanity_%")
      groups.each do |group|
        self.update_users_for_group(group)
      end
    end
  end
end

