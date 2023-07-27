# frozen_string_literal: true

module DiscourseGitcoinPassport
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseGitcoinPassport
  end
end