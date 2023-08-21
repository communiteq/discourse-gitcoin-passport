BadgeGrouping.seed_once(:name) do |bg|
    bg.name = SiteSetting.gitcoin_passport_badge_group
    bg.position = BadgeGrouping.maximum(:position) + 1
    bg.description = "Unique Humanity Score"
end