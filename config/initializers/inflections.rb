# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, "\\1en"
#   inflect.singular /^(ox)en/i, "\\1"
#   inflect.irregular "person", "people"
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym "RESTful"
# end

# OmniAuth capitalizes the "A": the gem namespace is `OmniAuth`, but without
# this rule ActiveSupport (and therefore Zeitwerk, which builds constants from
# file paths) inflects `lib/omniauth` as `Omniauth`. That mismatch makes eager
# loading (`config.eager_load = true`, i.e. CI) crash with
# `uninitialized constant Omniauth::Strategies::Hackclub`, so every spec file
# fails to boot. This one line makes `omniauth` -> `OmniAuth` everywhere.
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym "OmniAuth"
end
