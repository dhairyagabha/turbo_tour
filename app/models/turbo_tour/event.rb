# frozen_string_literal: true

module TurboTour
  class Event < ActiveRecord::Base
    self.table_name = "turbo_tour_events"

    belongs_to :trackable, polymorphic: true, optional: true

    validates :session_id, presence: true
    validates :journey_name, presence: true
    validates :event_name, presence: true

    scope :for_journey, ->(name) { where(journey_name: name) }
    scope :for_session, ->(id) { where(session_id: id) }
    scope :completed, -> { where(event_name: "complete") }
    scope :skipped, -> { where(event_name: "skip") }
  end
end
