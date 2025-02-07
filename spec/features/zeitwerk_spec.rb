# frozen_string_literal: true

require 'rails_helper'

# See https://guides.rubyonrails.org/classic_to_zeitwerk_howto.html#check-zeitwerk-compliance-in-the-test-suite
RSpec.describe 'Zeitwerk compliance' do
  it 'eager loads all files without errors' do
    expect { Rails.application.eager_load! }.not_to raise_error
  end
end
