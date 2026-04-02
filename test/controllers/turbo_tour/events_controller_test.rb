# frozen_string_literal: true

require "test_helper"

class TurboTour::EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    TurboTour::Event.delete_all
    TurboTour.configuration.analytics_enabled = true
    host! "www.example.com"
  end

  test "creates an event with valid params" do
    post "/turbo_tour/events",
      params: { event: valid_event_params },
      as: :json

    assert_response :created
    assert_equal 1, TurboTour::Event.count

    event = TurboTour::Event.last
    assert_equal "test-session", event.session_id
    assert_equal "dashboard_intro", event.journey_name
    assert_equal "create_project", event.step_name
    assert_equal 0, event.step_index
    assert_equal 3, event.total_steps
    assert_equal "start", event.event_name
  end

  test "normalizes long event names to short form" do
    post "/turbo_tour/events",
      params: { event: valid_event_params.merge(event_name: "turbo-tour:complete") },
      as: :json

    assert_response :created
    assert_equal "complete", TurboTour::Event.last.event_name
  end

  test "captures ip address and user agent" do
    post "/turbo_tour/events",
      params: { event: valid_event_params },
      headers: { "User-Agent" => "TestBrowser/1.0" },
      as: :json

    assert_response :created
    event = TurboTour::Event.last
    assert_not_nil event.ip_address
    assert_equal "TestBrowser/1.0", event.user_agent
  end

  test "associates event with trackable from current_user_resolver" do
    user = User.create!(name: "Tour Taker")
    TurboTour.configuration.current_user_resolver = -> { User.find(user.id) }

    post "/turbo_tour/events",
      params: { event: valid_event_params },
      as: :json

    assert_response :created
    event = TurboTour::Event.last
    assert_equal user, event.trackable
  end

  test "handles nil from current_user_resolver gracefully" do
    TurboTour.configuration.current_user_resolver = -> { nil }

    post "/turbo_tour/events",
      params: { event: valid_event_params },
      as: :json

    assert_response :created
    assert_nil TurboTour::Event.last.trackable
  end

  test "handles exception in current_user_resolver gracefully" do
    TurboTour.configuration.current_user_resolver = -> { raise "boom" }

    post "/turbo_tour/events",
      params: { event: valid_event_params },
      as: :json

    assert_response :created
    assert_nil TurboTour::Event.last.trackable
  end

  test "returns not found when analytics is disabled" do
    TurboTour.configuration.analytics_enabled = false

    post "/turbo_tour/events",
      params: { event: valid_event_params },
      as: :json

    assert_response :not_found
    assert_equal 0, TurboTour::Event.count
  end

  test "returns unprocessable entity with missing required params" do
    post "/turbo_tour/events",
      params: { event: { session_id: "s1" } },
      as: :json

    assert_response :unprocessable_entity
  end

  private

  def valid_event_params
    {
      session_id: "test-session",
      journey_name: "dashboard_intro",
      step_name: "create_project",
      step_index: 0,
      total_steps: 3,
      event_name: "turbo-tour:start",
      progress: 0.33,
      progress_percentage: 33
    }
  end
end
