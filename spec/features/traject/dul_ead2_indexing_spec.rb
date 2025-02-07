# frozen_string_literal: true

# Adapted from ArcLight core spec. See:
# https://github.com/projectblacklight/arclight/blob/master/spec/features/traject/ead2_indexing_spec.rb

require 'rails_helper'
require 'nokogiri'

# rubocop:disable RSpec/MultipleMemoizedHelpers, RSpec/MultipleExpectations, RSpec/NestedGroups
RSpec.describe 'EAD2002 traject indexing' do
  subject(:result) do
    indexer.map_record(record)
  end

  let(:indexer) do
    Traject::Indexer::NokogiriIndexer.new.tap do |i|
      i.load_config_file(Rails.root.join('lib/traject/dul_ead2_config.rb'))
    end
  end

  let(:all_components) do
    components(result) - [result]
  end

  let(:fixture_file) do
    File.read(fixture_path)
  end

  let(:nokogiri_reader) do
    DulArclight::DulCompressedReader.new(fixture_file.to_s, indexer.settings)
  end

  let(:records) do
    nokogiri_reader.to_a
  end

  let(:record) do
    records.first
  end

  def components(result)
    [result] + result.fetch('components', []).flat_map do |component|
      components(component)
    end
  end

  before do
    ENV['REPOSITORY_ID'] = nil
  end

  after do # ensure we reset these otherwise other tests will fail
    ENV['REPOSITORY_ID'] = nil
  end

  describe 'DUL basic indexing customizations' do
    let(:fixture_path) do
      Rails.root.join('spec/fixtures/ead/rubenstein/rushbenjaminandjulia.xml')
    end

    describe 'Format field from genreform' do
      it 'captures genreform for Format' do
        expect(result['genreform_ssim']).to include('Diaries')
      end

      it 'omits genreform from Subject' do
        expect(result['access_subjects_ssim']).to \
          eq(['Physicians -- Records and correspondence.',
              'Medicine -- Study and teaching -- Pennsylvania -- Philadelphia',
              'Mental illness -- Treatment -- United States -- History -- 19th century',
              'Yellow Fever -- Pennsylvania -- Philadelphia'])
      end
    end

    describe 'UA record groups for non-UA collections' do
      it 'skips record groups unless archdesc/did/unitid begins with UA.' do
        expect(result['ua_record_group_ssim']).to be_nil
      end
    end

    describe 'Permalink' do
      it 'captures permalink' do
        expect(result['permalink_ssi']).to eq(['https://idn.duke.edu/ark:/87924/m1907q'])
      end
    end

    describe 'ARK' do
      it 'captures ARK (derived from permalink)' do
        expect(result['ark_ssi']).to eq(['ark:/87924/m1907q'])
      end
    end

    describe 'Extent with carrier' do
      it 'wraps carrier extent values in parentheses' do
        expect(result['extent_ssm']).to eq(['0.8 Linear Feet (3 boxes, 2 volumes)'])
      end
    end

    describe 'Bib number indexing' do
      describe 'collection level' do
        it 'gets bib number' do
          expect(result['bibnum_ssim'].first).to eq '002164677'
        end
      end

      describe 'component level' do
        it 'gets bib number from collection / top level' do
          component = result['components'].find do |c|
            c['id'] == ['rushbenjaminandjulia_aspace_60bc65ac982c71ade8c13641188f6dbc']
          end
          expect(component['bibnum_ssim'].first).to eq '002164677'
        end
      end
    end

    describe 'component ancestor IDs' do
      let(:component) do
        all_components.find do |c|
          c['id'] == ['rushbenjaminandjulia_aspace_5f67670f35d7b87a014f665136ab236e']
        end
      end

      it 'captures its ancestor IDs in parent_ids_ssim' do
        expect(component['parent_ids_ssim']).to eq %w[rushbenjaminandjulia
                                                      rushbenjaminandjulia_aspace_3c7e06b31aff79e4b5b887524157f1fb]
      end

      it 'does not capture ancestor IDs in the deprecated parent_ssim' do
        expect(component['parent_ssim']).to be_nil
      end
    end
  end

  describe 'UA collection indexing' do
    let(:fixture_path) do
      Rails.root.join('spec/fixtures/ead/ua/uaduketaekwondo.xml')
    end

    describe 'UA record groups' do
      it 'captures the top level group' do
        expect(result['ua_record_group_ssim']).to include('31 -- Student/Campus Life')
      end

      it 'captures the sub group preceded by its parent group' do
        expect(result['ua_record_group_ssim']).to \
          include('31 -- Student/Campus Life > 11 -- Student Organizations - Recreational Sports')
      end
    end
  end

  describe 'restrictions inheritance & indexing' do
    let(:fixture_path) do
      Rails.root.join('spec/fixtures/ead/rubenstein/restrictionstest.xml')
    end

    describe 'series with own restrictions' do
      it 'gets its own restrictions' do
        component = all_components.find { |c| c['id'] == ['restrictionstest_aspace_testrestrict_series_a'] }
        expect(component['accessrestrict_html_tesm'].count).to eq 1
        expect(component['accessrestrict_html_tesm'].first).to eq '<p>Access Restriction A</p>'
        expect(component['phystech_html_tesm'].count).to eq 1
        expect(component['phystech_html_tesm'].first).to eq '<p>Phystech Restriction A</p>'
      end
    end

    describe 'series without restrictions' do
      it 'gets no restrictions, not even from top-level archdesc' do
        component = all_components.find { |c| c['id'] == ['restrictionstest_aspace_testrestrict_series_b'] }
        expect(component['accessrestrict_html_tesm']).to be_nil
        expect(component['userestrict_html_tesm']).to be_nil
        expect(component['phystech_html_tesm']).to be_nil
      end
    end

    describe 'subseries with restrictions under a restricted series' do
      it 'gets only its own restrictions, not from its parent series' do
        component = all_components.find { |c| c['id'] == ['restrictionstest_aspace_testrestrict_subseries_c'] }
        expect(component['accessrestrict_html_tesm'].count).to eq 1
        expect(component['accessrestrict_html_tesm'].first).to eq '<p>Access Restriction C</p>'
        expect(component['phystech_html_tesm'].count).to eq 1
        expect(component['phystech_html_tesm'].first).to eq '<p>Phystech Restriction C</p>'
      end
    end

    # rubocop:disable RSpec/ExampleLength
    describe 'subseries without restrictions under a restricted series' do
      it 'gets restrictions from its parent series' do
        component = all_components.find do |c|
          c['id'] == ['restrictionstest_aspace_testrestrict_subseries_d']
        end
        expect(component['accessrestrict_html_tesm'].count).to eq 1
        expect(component['accessrestrict_html_tesm'].first).to eq '<p>Access Restriction A</p>'
        expect(component['userestrict_html_tesm'].count).to eq 1
        expect(component['userestrict_html_tesm'].first).to eq '<p>Use Restriction A</p>'
        expect(component['phystech_html_tesm'].count).to eq 1
        expect(component['phystech_html_tesm'].first).to eq '<p>Phystech Restriction A</p>'
      end
    end
    # rubocop:enable RSpec/ExampleLength

    describe 'subseries without restrictions, under a series without restrictions' do
      it 'gets no restrictions, not even from top-level archdesc' do
        component = all_components.find { |c| c['id'] == ['restrictionstest_aspace_testrestrict_subseries_f'] }
        expect(component['accessrestrict_html_tesm']).to be_nil
        expect(component['userestrict_html_tesm']).to be_nil
        expect(component['phystech_html_tesm']).to be_nil
      end
    end

    describe 'file with restrictions under a restricted subseries' do
      it 'gets only its own restrictions, not from its parent subseries nor its ancestor series' do
        component = all_components.find { |c| c['id'] == ['restrictionstest_aspace_testrestrict_file_h'] }
        expect(component['accessrestrict_html_tesm'].count).to eq 1
        expect(component['accessrestrict_html_tesm'].first).to eq '<p>Access Restriction H</p>'
        expect(component['phystech_html_tesm'].count).to eq 1
        expect(component['phystech_html_tesm'].first).to eq '<p>Phystech Restriction H</p>'
      end
    end

    describe 'file without restrictions 2 deep under a restricted series' do
      it 'gets restrictions from its grandparent series' do
        component = all_components.find { |c| c['id'] == ['restrictionstest_aspace_testrestrict_file_i'] }
        expect(component['accessrestrict_html_tesm'].count).to eq 1
        expect(component['accessrestrict_html_tesm'].first).to eq '<p>Access Restriction A</p>'
        expect(component['phystech_html_tesm'].count).to eq 1
        expect(component['phystech_html_tesm'].first).to eq '<p>Phystech Restriction A</p>'
      end
    end
  end

  describe 'Alma bib ID indexing' do
    let(:fixture_path) do
      Rails.root.join('spec/fixtures/ead/rubenstein/alma-test.xml')
    end

    describe 'collection level' do
      it 'gets Alma bib number' do
        expect(result['bibnum_ssim'].first).to eq '99111111111118501'
      end
    end

    describe 'component level' do
      it 'gets Alma bib number from collection / top level' do
        component = result['components'].find do |c|
          c['id'] == ['alma-test_aspace_alma_component']
        end
        expect(component['bibnum_ssim'].first).to eq '99111111111118501'
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers, RSpec/MultipleExpectations, RSpec/NestedGroups
