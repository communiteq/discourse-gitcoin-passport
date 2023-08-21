bg = BadgeGrouping.where(name: SiteSetting.gitcoin_passport_badge_group).first

[
    ["Unique Humanity Bronze", "bronze", BadgeType::Bronze],
    ["Unique Humanity Silver", "silver", BadgeType::Silver],
    ["Unique Humanity Gold", "gold", BadgeType::Gold]
].each do |name, lvl_text, level|
    Badge.seed_once(:name) do |badge|
        score = SiteSetting.get("gitcoin_passport_badge_#{lvl_text}_score")
        
        badge.name = name
        badge.default_icon = "fingerprint"
        badge.description = "Has a unique humanity score of at least #{score}"
        badge.badge_type_id = level
        badge.default_badge_grouping_id = bg.id
        badge.listable = true
        badge.default_allow_title = true
        badge.target_posts = false
        badge.default_enabled = true
        badge.auto_revoke = true
        badge.show_posts = false
        badge.system = true
    end
end
