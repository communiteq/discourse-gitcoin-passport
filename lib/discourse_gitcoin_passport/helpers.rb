# frozen_string_literal: true

module DiscourseGitcoinPassport
  module Helpers
    def self.change_automatic_groups(levels)
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
        # TODO run update_users_for_all_groups async
      end
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

    def self.update_users_for_group(group)
      level = group.name[/unique_humanity_(\d+)/,1].to_i
      formatted_level = sprintf('%06.2f', level)
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

