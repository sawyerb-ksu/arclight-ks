# frozen_string_literal: true

RSpec.describe BuildSuggestJob do
  it 'works without errors' do
    expect { described_class.perform_now }.not_to raise_error
  end
end
