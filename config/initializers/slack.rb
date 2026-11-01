# Load the Slack Ruby Client early so SlackInvitations can use it.
# The gem is listed in the Gemfile, so this only ensures the require happens.
require "slack-ruby-client"