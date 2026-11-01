# frozen_string_literal: true

# Usage:
#   bin/rails "invite:rsvped_users"              # invite every RSVPed user to Slack
#   bin/rails "invite:rsvped_users[dry]"         # report only, no Slack API calls
#   bin/rails "invite:rsvped_users[dry, 25]"     # dry-run, at most 25 users
#
# Finds every user who has an RSVP and invites them to the Slack channel via
# SlackBotService. Best-effort: users without a slack_id are skipped, users
# already in the channel are reported but not re-invited, Slack failures are
# logged and swallowed, and the task never raises.

namespace :invite do
  desc "Invite every RSVPed user to the Slack channel"
  task :rsvped_users, %i[mode limit] => :environment do |_task, args|
    mode = args[:mode]&.to_s
    dry_run = %w[dry dry-run].include?(mode)
    limit = args[:limit]&.to_i

    puts dry_run ? "=== DRY RUN: no Slack API calls will be made ===" : "=== Inviting RSVPed users to Slack ==="
    puts

    rsvps = Rsvp.order(:created_at).includes(:user)
    rsvps = rsvps.limit(limit) if limit&.positive?

    total = 0
    invited = 0
    already_in_channel = 0
    skipped_no_slack_id = 0
    failures = []

    # NOTE: use `each`, not `find_each`: find_each ignores `order` and
    # `limit` (it re-applies its own batch ordering/limit), which would break
    # the `limit` argument and the created_at ordering. RSVP volume is small
    # enough that batched iteration is unnecessary.
    rsvps.each do |rsvp|
      user = rsvp.user
      total += 1

      if user.nil?
        skipped_no_slack_id += 1
        puts "  [skip]   rsvp ##{rsvp.id}: no user"
        next
      end

      slack_id = user.slack_id.to_s.strip

      if slack_id.blank?
        skipped_no_slack_id += 1
        puts "  [skip]   user ##{user.id} (#{user.name}): no slack_id"
        next
      end

      if dry_run
        puts "  [dry]    would invite user ##{user.id} (#{user.name}) -> #{slack_id}"
        next
      end

      already = begin
        SlackBotService.in_channel?(slack_id)
      rescue StandardError => e
        Rails.logger.error("[Invite] could not check membership for user ##{user.id} (#{slack_id}): #{e.class}: #{e.message}")
        nil
      end

      if already
        already_in_channel += 1
        puts "  [already] user ##{user.id} (#{user.name}) is already in the channel"
        next
      end

      result = begin
        SlackBotService.add_to_channel(slack_id:)
      rescue StandardError => e
        Rails.logger.error("[Invite] unexpected invite error for user ##{user.id} (#{slack_id}): #{e.class}: #{e.message}")
        false
      end

      if result
        invited += 1
        puts "  [invite] user ##{user.id} (#{user.name}) -> #{slack_id}"
      else
        failures << "user ##{user.id} (#{user.name}) -> #{slack_id}"
        puts "  [fail]   user ##{user.id} (#{user.name}) -> #{slack_id}: Slack invite returned false"
      end
    end

    puts
    puts "=== Done: #{total} RSVPed user(s), #{invited} invited, #{already_in_channel} already in the channel, #{skipped_no_slack_id} skipped (no slack_id) ==="
    puts "#{failures.count} invite(s) could not be completed (see above)." if failures.any?
  end
end
