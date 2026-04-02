# frozen_string_literal: true

module TurboTour
  class EventsController < ActionController::Base
    protect_from_forgery with: :null_session
    before_action :verify_analytics_enabled

    EVENT_NAME_MAP = {
      "turbo-tour:start" => "start",
      "turbo-tour:next" => "next",
      "turbo-tour:previous" => "previous",
      "turbo-tour:complete" => "complete",
      "turbo-tour:skip-tour" => "skip"
    }.freeze

    def create
      event = TurboTour::Event.new(event_params)
      event.trackable = resolve_trackable
      event.ip_address = request.remote_ip
      event.user_agent = request.user_agent

      if event.save
        head :created
      else
        head :unprocessable_entity
      end
    end

    private

    def event_params
      permitted = params.require(:event).permit(
        :session_id, :journey_name, :step_name, :step_index,
        :total_steps, :event_name, :progress, :progress_percentage, :reason
      )

      if permitted[:event_name]
        permitted[:event_name] = EVENT_NAME_MAP[permitted[:event_name]] || permitted[:event_name]
      end

      permitted
    end

    def resolve_trackable
      resolver = TurboTour.configuration.current_user_resolver
      return nil unless resolver

      instance_exec(&resolver)
    rescue => e
      Rails.logger.warn("[TurboTour] current_user_resolver failed: #{e.message}")
      nil
    end

    def verify_analytics_enabled
      head :not_found unless TurboTour.analytics_enabled?
    end
  end
end
