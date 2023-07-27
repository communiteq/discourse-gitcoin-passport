# frozen_string_literal: true

DiscourseGitcoinPassport::Engine.routes.draw do
  post "/refresh_score" => "score#refresh"
end

Discourse::Application.routes.draw do
  mount ::DiscourseGitcoinPassport::Engine, at: "/gitcoin_passport"
end
