# frozen_string_literal: true

require 'rails_helper'

class TestController
  include FieldConfigHelpers
end

RSpec.describe FieldConfigHelpers do
  subject(:helper) { TestController.new }

  describe '#singularize_extent' do
    it 'singularizes poorly worded extents like 1 boxes' do
      content = helper.singularize_extent(value: ['1 boxes', '11 boxes', '1 albums'])
      expect(content).to eq '1 box, 11 boxes, and 1 album'
    end
  end

  describe '#keep_raw_values' do
    it 'returns the raw array of values' do
      content = helper.keep_raw_values(
        value: %w[one two three]
      )
      expect(content).to eq(%w[one two three])
    end
  end
end
