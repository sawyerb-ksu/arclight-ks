# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrDocument do
  let(:doc) { described_class.new(attrs) }

  describe '#containers' do
    subject { doc.containers }

    context 'when containers_ssim is empty' do
      let(:attrs) { { containers_ssim: [] } }

      it { is_expected.to eq([]) }
    end

    context 'when containers_ssim is present' do
      let(:attrs) { { containers_ssim: ['box MN6'] } }

      it { is_expected.to eq(['Box MN6']) }
    end
  end
end
