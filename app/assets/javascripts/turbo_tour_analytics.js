const csrfToken = () => {
  const meta = document.querySelector('meta[name="csrf-token"]')
  return meta ? meta.getAttribute("content") : null
}

const endpointUrl = () => {
  const meta = document.querySelector('meta[name="turbo-tour-analytics-url"]')
  return meta ? meta.getAttribute("content") : "/turbo_tour/events"
}

const sendEvent = (eventName, detail) => {
  const url = endpointUrl()
  if (!url) return

  const token = csrfToken()
  const body = {
    event: {
      session_id: detail.sessionId || detail.session_id,
      journey_name: detail.journeyName || detail.journey_name,
      step_name: detail.stepName || detail.step_name,
      step_index: detail.stepIndex ?? detail.step_index,
      total_steps: detail.totalSteps ?? detail.total_steps,
      event_name: eventName,
      progress: detail.progress,
      progress_percentage: detail.progressPercentage ?? detail.progress_percentage,
      reason: detail.reason || null
    }
  }

  fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
      ...(token ? { "X-CSRF-Token": token } : {})
    },
    body: JSON.stringify(body),
    keepalive: true
  }).catch((error) => {
    console.warn("[TurboTour Analytics] Failed to send event:", error)
  })
}

const analyticsExtension = {
  name: "turbo-tour-analytics",

  onStart(context) { sendEvent("turbo-tour:start", context) },
  onNext(context) { sendEvent("turbo-tour:next", context) },
  onPrevious(context) { sendEvent("turbo-tour:previous", context) },
  onComplete(context) { sendEvent("turbo-tour:complete", context) },
  onSkip(context) { sendEvent("turbo-tour:skip-tour", context) }
}

if (window.TurboTour) {
  window.TurboTour.registerExtension(analyticsExtension)
} else {
  document.addEventListener("DOMContentLoaded", () => {
    window.TurboTour?.registerExtension(analyticsExtension)
  })
}

export { analyticsExtension }
export default analyticsExtension
