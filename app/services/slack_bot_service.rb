# frozen_string_literal: true

class SlackBotService
  PAGE_LIMIT = 1000

  def self.add_to_channel(user = nil, slack_id: nil, channel_id: nil, token: nil, default_channel_id: nil, **opts)
    user ||= opts[:user]
    raw = slack_id.presence || user
    resolved_slack_id = normalize_slack_id(raw)
    new(token: token || @token,
        default_channel_id: default_channel_id || @default_channel_id)
      .add_to_channel(slack_id: resolved_slack_id, channel_id: channel_id)
  end

  def self.in_channel?(slack_id, channel_id = nil, token: nil, default_channel_id: nil)
    new(token: token || @token,
        default_channel_id: default_channel_id || @default_channel_id)
      .in_channel?(slack_id, channel_id)
  end

  def self.normalize_slack_id(value)
    value = value.slack_id if value.is_a?(User)
    value.to_s.strip
  end

  def initialize(token: ENV["SLACK_OAUTH_TOKEN"], default_channel_id: ENV["SLACK_CHANNEL_ID"], channel: nil)
    @token = token.to_s.strip
    fallback = default_channel_id.presence || channel.presence
    @default_channel_id = fallback.to_s.strip
    @channel_id = @default_channel_id
    @client = Slack::Web::Client.new(token: @token) if @token.present?
  end

  def checks(channel = nil)
    channel ||= @default_channel_id
    if @token.blank? || @client.nil?
      Rails.logger.error("[SlackBot] Error SLACK_OAUTH_TOKEN missing")
      return false
    end
    if channel.blank?
      Rails.logger.warn("[SlackBot] Warn SLACK_CHANNEL_ID missing")
      return false
    end
    true
  end

  def in_channel?(slack_id, channel_id = nil)
    slack_id = self.class.normalize_slack_id(slack_id)
    channel = channel_id.presence || @default_channel_id

    if slack_id.blank?
      Rails.logger.warn("[SlackBot] skip member check: blank slack_id")
      return false
    end

    return false unless checks(channel)

    cursor = nil
    loop do
      options = { channel: channel, limit: PAGE_LIMIT, cursor: cursor }.compact
      response = @client.conversations_members(**options)
      return true if Array(response.members).include?(slack_id)

      cursor = response.response_metadata&.next_cursor
      break if cursor.blank?
    end
    false
  rescue Slack::Web::Api::Errors::SlackError => e
    case e.error
    when "is_archived", "channel_not_found"
      Rails.logger.warn("[SlackBot] check member failed (#{e.error}) for #{slack_id} -> #{channel}")
      false
    when "not_in_channel", "channel_not_joined"
      Rails.logger.error("[SlackBot] bot must join #{channel} first (#{e.error})")
      false
    else
      Rails.logger.error("[SlackBot] check member failed (#{e.error}) for #{slack_id}: #{e.message}")
      false
    end
  end

  def add_to_channel(slack_id: nil, channel_id: nil, **opts)
    slack_id = self.class.normalize_slack_id(slack_id.presence || opts[:user])
    channel = channel_id.presence || @default_channel_id

    if slack_id.blank?
      Rails.logger.warn("[SlackBot] skip invite: blank slack_id")
      return false
    end

    return false unless checks(channel)
    return true if in_channel?(slack_id, channel)

    @client.conversations_invite(channel: channel, users: slack_id)
    Rails.logger.info("[SlackBot] invited #{slack_id} to channel (#{channel})")
    true
  rescue Slack::Web::Api::Errors::SlackError => e
    case e.error
    when "cant_invite_self", "is_archived", "channel_not_found", "user_not_found"
      Rails.logger.warn("[SlackBot] invite failed (#{e.error}) for #{slack_id} -> #{channel}")
      false
    when "already_in_channel"
      Rails.logger.info("[SlackBot] already in channel #{channel} for #{slack_id}")
      true
    when "not_in_channel", "channel_not_joined"
      # Fix: invite the bot user into the channel once manually in Slack.
      Rails.logger.error("[SlackBot] bot must join #{channel} first (#{e.error})")
      false
    else
      Rails.logger.error("[SlackBot] invite failed (#{e.error}) for #{slack_id}: #{e.message}")
      false
    end
  end
end
