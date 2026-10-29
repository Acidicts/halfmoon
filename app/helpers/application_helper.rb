# frozen_string_literal: true

module ApplicationHelper
  def flash_alert_type(type)
    case type.to_s
    when "notice", "success" then "success"
    when "alert", "error" then "error"
    when "warning", "warn" then "warn"
    else "info"
    end
  end
end
