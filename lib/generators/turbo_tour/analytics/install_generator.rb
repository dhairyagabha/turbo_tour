# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module TurboTour
  module Generators
    module Analytics
      class InstallGenerator < Rails::Generators::Base
        include ActiveRecord::Generators::Migration

        source_root File.expand_path("templates", __dir__)

        desc "Installs TurboTour analytics: migration, route mount, and configuration."

        def copy_migration
          migration_template(
            "create_turbo_tour_events.rb.erb",
            "db/migrate/create_turbo_tour_events.rb"
          )
        end

        def mount_engine_routes
          routes_path = File.join(destination_root, "config/routes.rb")

          unless File.exist?(routes_path)
            say_status(:skipped, "config/routes.rb not found. Add `mount TurboTour::Engine, at: \"/turbo_tour\"` to your routes manually.", :yellow)
            return
          end

          route 'mount TurboTour::Engine, at: "/turbo_tour"'
        end

        def enable_analytics_in_initializer
          relative_path = "config/initializers/turbo_tour.rb"
          full_path = File.join(destination_root, relative_path)

          unless File.exist?(full_path)
            say_status(:skipped, "#{relative_path} not found. Run rails generate turbo_tour:install first.", :yellow)
            return
          end

          contents = File.binread(full_path)

          if contents.include?("analytics_enabled")
            say_status(:identical, "#{relative_path} already configures analytics", :blue)
            return
          end

          inject_into_file relative_path, after: "TurboTour.configure do |config|\n" do
            "  # Analytics — records tour events server-side\n" \
            "  config.analytics_enabled = true\n" \
            "  # config.current_user_resolver = -> { current_user }\n"
          end
        end

        def register_analytics_js
          index_path = "app/javascript/controllers/index.js"
          return unless File.exist?(index_path)

          contents = File.binread(index_path)

          if contents.include?("turbo_tour_analytics")
            say_status(:identical, "#{index_path} already imports turbo_tour_analytics", :blue)
            return
          end

          append_to_file index_path, "\nimport \"turbo_tour_analytics\"\n"
        end

        def show_next_steps
          say_status(:next, "Run `rails db:migrate` to create the turbo_tour_events table.", :green)
          say_status(:next, "Add `<%= turbo_tour_analytics_meta_tag %>` to your application layout.", :green)
          say_status(:next, "Uncomment and configure `current_user_resolver` in your initializer to associate events with users.", :green)
        end
      end
    end
  end
end
