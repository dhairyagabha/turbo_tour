# frozen_string_literal: true

require "test_helper"
require "generators/turbo_tour/analytics/install_generator"

class TurboTourAnalyticsInstallGeneratorTest < Rails::Generators::TestCase
  tests TurboTour::Generators::Analytics::InstallGenerator
  destination File.expand_path("../tmp/analytics_generator", __dir__)

  setup :prepare_destination

  test "creates the migration file" do
    write_destination_file("config/initializers/turbo_tour.rb", initializer_content)

    run_generator

    assert_migration "db/migrate/create_turbo_tour_events.rb", /create_table :turbo_tour_events/
  end

  test "adds engine mount to routes" do
    write_destination_file("config/initializers/turbo_tour.rb", initializer_content)
    write_destination_file("config/routes.rb", "Rails.application.routes.draw do\nend\n")

    run_generator

    assert_file "config/routes.rb", /mount TurboTour::Engine/
  end

  test "injects analytics config into initializer" do
    write_destination_file("config/initializers/turbo_tour.rb", initializer_content)

    run_generator

    assert_file "config/initializers/turbo_tour.rb", /analytics_enabled = true/
    assert_file "config/initializers/turbo_tour.rb", /current_user_resolver/
  end

  test "skips analytics config when already present" do
    write_destination_file("config/initializers/turbo_tour.rb",
      "TurboTour.configure do |config|\n  config.analytics_enabled = true\nend\n")

    run_generator

    contents = File.read(File.join(destination_root, "config/initializers/turbo_tour.rb"))
    assert_equal 1, contents.scan("analytics_enabled").length
  end

  private

  def initializer_content
    "TurboTour.configure do |config|\n  config.highlight_classes = \"\"\nend\n"
  end

  def write_destination_file(relative_path, contents)
    path = File.join(destination_root, relative_path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, contents)
  end
end
