# frozen_string_literal: true

# ApplicationMailer is the base class for creating email-related classes
# in a Rails application. It provides a framework for sending email
# notifications and managing email templates and layouts.

# DUL CUSTOMIZATION: this "default from" seems to take precedence over the
# config in application.rb, so we're commenting it out here.
class ApplicationMailer < ActionMailer::Base
  # default from: 'from@example.com'
  layout 'mailer'
end
