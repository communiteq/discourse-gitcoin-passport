# frozen_string_literal: true

class GroupLevelsValidator
  def self.valid_numbers_string?(value)
    segments = value.split(",")
    segments.all? do |segment|
      trimmed_segment = segment.strip
      is_integer = trimmed_segment.chars.all? { |char| char >= '0' && char <= '9' }
      if is_integer
        number = trimmed_segment.to_i
        number.between?(0, 100)
      else
        false
      end
    end
  end

  def initialize(opts = {})
    @opts = opts
  end
  
  def valid_value?(val)
    unless GroupLevelsValidator.valid_numbers_string?(val)
      @err = I18n.t("gitcoin_passport.group_levels_validator.number_error")
      return false
    end

    # get all group references in category permissions and site settings
    # settings type 20 = group_list, 19 = group
    used_group_ids = CategoryGroup.pluck(:group_id) +
      SiteSetting.where(data_type: 20).pluck(:value).join("|").split("|").map { |g| g.to_i }.uniq +
      Group.where(name: SiteSetting.where(data_type: 19).pluck(:value)).pluck(:id)
    uh_group_ids = Group.where("name LIKE ?", "unique_humanity_%").pluck(:id)
    used_uh_groups = Group.where(id: used_group_ids & uh_group_ids)
    used_uh_levels = used_uh_groups.map { |group| group[:name][/unique_humanity_(\d+)/, 1] }.compact.map(&:to_i).uniq

    # raise an error if any levels that are in use will disappear
    proposed_uh_levels = val.split(",").map { |level| level.to_i }
    if (used_uh_levels - proposed_uh_levels).count > 0
      lvl_string = (used_uh_levels - proposed_uh_levels).sort.join (", ")
      plural = (used_uh_levels - proposed_uh_levels).count > 1 ? "more" : "one"
      @err = I18n.t("gitcoin_passport.group_levels_validator.inuse_error.#{plural}", { levels: lvl_string })
      return false
    end

    true
  end
  
  def error_message
    @err
  end
end
  