# frozen_string_literal: true

require "test_helper"

class TurboTourJourneyLoaderTest < ActiveSupport::TestCase
  test "loads and normalizes journeys from yaml files" do
    with_temporary_directory do |root|
      write_file(root.join("config/turbo_tours/dashboard.yml"), <<~YAML)
        journeys:
          dashboard_intro:
            - name: create_project
              target: create-project
              title: Create your first project
              body: Click here to begin.
      YAML

      loader = TurboTour::JourneyLoader.new(configuration: TurboTour.configuration, root: root)

      assert_equal(
        [
          {
            "name" => "create_project",
            "target" => "create-project",
            "title" => "Create your first project",
            "body" => "Click here to begin."
          }
        ],
        loader.fetch(:dashboard_intro)
      )
      assert_equal ["dashboard_intro"], loader.all.keys
    end
  end

  test "slice returns only the requested journeys" do
    with_temporary_directory do |root|
      write_file(root.join("config/turbo_tours/journeys.yml"), <<~YAML)
        journeys:
          dashboard_intro:
            - name: create_project
              target: create-project
              title: Create your first project
              body: Click here to begin.
          invite_team:
            - name: invite_button
              target: invite-button
              title: Invite your team
              body: Bring collaborators into the workspace.
      YAML

      loader = TurboTour::JourneyLoader.new(configuration: TurboTour.configuration, root: root)

      assert_equal ["invite_team"], loader.slice(%w[invite_team]).keys
    end
  end

  test "raises a clear error for duplicate journeys" do
    with_temporary_directory do |root|
      write_file(root.join("config/turbo_tours/one.yml"), <<~YAML)
        journeys:
          dashboard_intro:
            - name: create_project
              target: create-project
              title: Create your first project
              body: Click here to begin.
      YAML

      write_file(root.join("config/turbo_tours/two.yml"), <<~YAML)
        journeys:
          dashboard_intro:
            - name: dashboard_metrics
              target: dashboard-metrics
              title: Track performance
              body: Follow your metrics here.
      YAML

      loader = TurboTour::JourneyLoader.new(configuration: TurboTour.configuration, root: root)
      error = assert_raises(TurboTour::JourneyLoader::DuplicateJourneyError) { loader.all }

      assert_match(/dashboard_intro/, error.message)
    end
  end

  test "raises a clear error when a step is missing required keys" do
    with_temporary_directory do |root|
      write_file(root.join("config/turbo_tours/invalid.yml"), <<~YAML)
        journeys:
          dashboard_intro:
            - name: create_project
              target: create-project
              title:
              body: Click here to begin.
      YAML

      loader = TurboTour::JourneyLoader.new(configuration: TurboTour.configuration, root: root)
      error = assert_raises(TurboTour::JourneyLoader::InvalidJourneyError) { loader.all }

      assert_match(/missing title/, error.message)
    end
  end

  test "raises a clear error for unknown journeys" do
    with_temporary_directory do |root|
      loader = TurboTour::JourneyLoader.new(configuration: TurboTour.configuration, root: root)
      error = assert_raises(TurboTour::JourneyLoader::InvalidJourneyError) { loader.fetch(:missing) }

      assert_match(/Unknown TurboTour journey/, error.message)
    end
  end

  test "supports locale-keyed hashes for title and body" do
    with_temporary_directory do |root|
      write_file(root.join("config/turbo_tours/multilang.yml"), <<~YAML)
        journeys:
          welcome:
            - name: greeting
              target: greeting-banner
              title:
                en: Welcome
                es: Bienvenido
              body:
                en: Let us show you around.
                es: Permítanos mostrarle el lugar.
      YAML

      loader = TurboTour::JourneyLoader.new(configuration: TurboTour.configuration, root: root)
      step = loader.fetch(:welcome).first

      assert_equal({ "en" => "Welcome", "es" => "Bienvenido" }, step["title"])
      assert_equal({ "en" => "Let us show you around.", "es" => "Permítanos mostrarle el lugar." }, step["body"])
    end
  end

  test "supports mixed plain strings and locale-keyed hashes in the same journey" do
    with_temporary_directory do |root|
      write_file(root.join("config/turbo_tours/mixed.yml"), <<~YAML)
        journeys:
          onboarding:
            - name: step_one
              target: step-one
              title:
                en: Hello
                fr: Bonjour
              body: This body is not localized.
            - name: step_two
              target: step-two
              title: Plain title
              body:
                en: English body
                fr: Corps français
      YAML

      loader = TurboTour::JourneyLoader.new(configuration: TurboTour.configuration, root: root)
      steps = loader.fetch(:onboarding)

      assert_equal({ "en" => "Hello", "fr" => "Bonjour" }, steps[0]["title"])
      assert_equal "This body is not localized.", steps[0]["body"]
      assert_equal "Plain title", steps[1]["title"]
      assert_equal({ "en" => "English body", "fr" => "Corps français" }, steps[1]["body"])
    end
  end
end
