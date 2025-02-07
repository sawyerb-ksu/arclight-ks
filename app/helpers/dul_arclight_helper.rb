# frozen_string_literal: true

# Helper methods specific to DUL ArcLight
# ---------------------------------------
module DulArclightHelper
  include EadFormatHelpers
  include FieldConfigHelpers

  # Shorthand to distinguish the homepage
  def homepage?
    current_page?(root_path)
  end

  def ask_rubenstein_url
    base_url = 'https://rubenstein.libanswers.com/index'
    [base_url, { referrer: request.original_url }.to_param].join('?')
  end
end
