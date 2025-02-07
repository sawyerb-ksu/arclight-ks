# frozen_string_literal: true

# Top-level controller injecting application-wide behavior
# via both Blacklight & ArcLight's initial generators
class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout :determine_layout if respond_to? :layout
end
