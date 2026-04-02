# frozen_string_literal: true

require "test_helper"

class TurboTourEventTest < ActiveSupport::TestCase
  test "validates presence of required fields" do
    event = TurboTour::Event.new

    assert_not event.valid?
    assert_includes event.errors[:session_id], "can't be blank"
    assert_includes event.errors[:journey_name], "can't be blank"
    assert_includes event.errors[:event_name], "can't be blank"
  end

  test "saves a valid event" do
    event = TurboTour::Event.new(
      session_id: "test-session-123",
      journey_name: "dashboard_intro",
      step_name: "create_project",
      step_index: 0,
      total_steps: 3,
      event_name: "start",
      progress: 0.33,
      progress_percentage: 33
    )

    assert event.save
    assert_not_nil event.created_at
  end

  test "supports polymorphic trackable association" do
    user = User.create!(name: "Test User")
    event = TurboTour::Event.create!(
      session_id: "test-session-456",
      journey_name: "dashboard_intro",
      event_name: "start",
      trackable: user
    )

    assert_equal "User", event.trackable_type
    assert_equal user.id, event.trackable_id
    assert_equal user, event.trackable
  end

  test "trackable is optional" do
    event = TurboTour::Event.new(
      session_id: "test-session-789",
      journey_name: "dashboard_intro",
      event_name: "start"
    )

    assert event.valid?
    assert_nil event.trackable
  end

  test "for_journey scope filters by journey name" do
    TurboTour::Event.create!(session_id: "s1", journey_name: "intro", event_name: "start")
    TurboTour::Event.create!(session_id: "s2", journey_name: "other", event_name: "start")

    assert_equal 1, TurboTour::Event.for_journey("intro").count
  end

  test "for_session scope filters by session id" do
    TurboTour::Event.create!(session_id: "session-a", journey_name: "intro", event_name: "start")
    TurboTour::Event.create!(session_id: "session-b", journey_name: "intro", event_name: "start")

    assert_equal 1, TurboTour::Event.for_session("session-a").count
  end

  test "completed scope filters for complete events" do
    TurboTour::Event.create!(session_id: "s1", journey_name: "intro", event_name: "complete")
    TurboTour::Event.create!(session_id: "s1", journey_name: "intro", event_name: "next")

    assert_equal 1, TurboTour::Event.completed.count
  end

  test "skipped scope filters for skip events" do
    TurboTour::Event.create!(session_id: "s1", journey_name: "intro", event_name: "skip")
    TurboTour::Event.create!(session_id: "s1", journey_name: "intro", event_name: "start")

    assert_equal 1, TurboTour::Event.skipped.count
  end

  setup do
    TurboTour::Event.delete_all
  end
end
