# frozen_string_literal: true

# This file holds DUL customizations to top-level (collection-level)
# EAD2002 indexing rules specified in ArcLight core.
# See: https://github.com/projectblacklight/arclight/blob/main/lib/arclight/traject/ead2_config.rb

# Note that to override any existing rules from core, we need to redefine them and
# blank out the result of the core indexing like this:
# context.output_hash['some_field_ssim'] = nil

require 'arclight'
require_relative '../dul_arclight/digital_object'
require_relative 'dul_arclight/dul_compressed_reader'
require_relative 'dul_arclight/ua_record_group'

settings do
  provide 'component_traject_config', File.join(__dir__, 'dul_ead2_component_config.rb')
  # DUL Customization: Swap out Arclight::Traject::NokogiriNamespacelessReader with
  # custom DulCompressedReader to remove namespaces AND squish unwanted whitespace.
  provide 'reader_class_name', 'DulArclight::DulCompressedReader'
end

load_config_file(File.expand_path("#{Arclight::Engine.root}/lib/arclight/traject/ead2_config.rb"))

# DUL CUSTOMIZATION: Get title with formatting tags intact
to_field 'title_html_ssm', extract_xpath('/ead/archdesc/did/unittitle', to_text: false)

# DUL CUSTOMIZATION: Special case for collection-level accessrestrict that is
# intended to display loudly as a warning banner throughout the collection
to_field 'accessrestrict_collection_banner_html_tesm',
         extract_xpath("/ead/archdesc/accessrestrict[head='banner' or head='Banner']/*[local-name()!='head']",
                       to_text: false)

# DUL CUSTOMIZATION: Permalink & ARK. NOTE the ARK will be derived from the
# permalink, and not the other way around; ARK is not stored atomically in the EAD.
# Strip out any wayward spaces or linebreaks that might end up in the url attribute
# and only capture the value if it's a real permalink (with an ARK).
to_field 'permalink_ssi' do |record, accumulator|
  url = record.at_xpath('/ead/eadheader/eadid').attribute('url')&.value || ''
  url.gsub(/[[:space:]]/, '')
  accumulator << url if url.include?('ark:')
end

to_field 'ark_ssi' do |_record, accumulator, context|
  next unless context.output_hash['permalink_ssi']

  permalink = context.output_hash['permalink_ssi'].first
  path = URI(permalink).path&.delete_prefix!('/')
  accumulator << path
end

# DUL CUSTOMIZATION: Bib ID (esp. for request integration & catalog links)
to_field 'bibnum_ssim',
         extract_xpath('/ead/eadheader/filedesc/notestmt/note/p/num[@type="aleph" or @type="bibnum"]')

# DUL CUSTOMIZATION: Remove genreform (Format) from being grouped in with Subject.
# We make a separate facet for Format.
# As of arclight 1.1.0, genreform is already indexed as genreform_ssim but only at collection level.
# ArcLight core also captures access_subjects_ssm but that appears to be unused.
to_field 'access_subjects_ssim',
         extract_xpath('/ead/archdesc/controlaccess', to_text: false) do |_record, accumulator, context|
  context.output_hash['access_subjects_ssim'] = nil
  accumulator.map! do |element|
    %w[subject function occupation].map do |selector|
      element.xpath(".//#{selector}").map(&:text)
    end
  end.flatten!
end

# DUL CUSTOMIZATION: UA Record Group Labels (top-level only)
# This field is used to create hierarchical facets via the blacklight-hierarchy gem.
# That gem does not accommodate configuring a label for the facet links that
# differs from the actual value, so we are indexing the (nested) labels here rather
# than e.g., 03:55.
to_field 'ua_record_group_ssim' do |_record, accumulator, context|
  id = context.output_hash['unitid_ssm']&.first&.split('.')
  if id[0] == 'UA'
    group = id[1]
    subgroup = id[2]
    accumulator << DulArclight::UaRecordGroup.new(group:).label
    accumulator << DulArclight::UaRecordGroup.new(group:, subgroup:).label
  end
end

# DUL CUSTOMIZATION: preserve formatting tags in normalized titles
to_field 'normalized_title_html_ssm' do |_record, accumulator, context|
  title = context.output_hash['title_html_ssm']&.first&.to_s
  dates = context.output_hash['normalized_date_ssm']&.first
  accumulator << Arclight::NormalizedTitle.new(title, dates).to_s
end

# DUL CUSTOMIZATION: use DUL rules for Digital Objects (esp. see role & xpointer)
to_field 'digital_objects_ssm',
         extract_xpath('/ead/archdesc/did/dao|/ead/archdesc/dao', to_text: false) do |_record, accumulator, context|
  # clear out the digital_objects_ssm data captured from core config
  context.output_hash['digital_objects_ssm'] = nil
  accumulator.map! do |dao|
    label = dao.attributes['title']&.value ||
            dao.attributes['xlink:title']&.value ||
            dao.xpath('daodesc/p')&.text
    href = (dao.attributes['href'] || dao.attributes['xlink:href'])&.value
    role = (dao.attributes['role'] || dao.attributes['xlink:role'])&.value
    xpointer = (dao.attributes['xpointer'] || dao.attributes['xlink:xpointer'])&.value
    DulArclight::DigitalObject.new(label:, href:, role:, xpointer:).to_json
  end
end

# DUL CUSTOMIZATION: omit DAO @role electronic-record-* from counting as online content
# as they are not really online and thus shouldn't get the icon/facet value.
to_field 'has_online_content_ssim',
         extract_xpath('.//dao[not(starts-with(@role,"electronic-record"))]') do |_record, accumulator, context|
  context.output_hash['has_online_content_ssim'] = nil
  accumulator.replace([accumulator.any?])
end

# DUL CUSTOMIZATION: count all online access DAOs from this level down; omit the
# electronic-record ones as they are not really online access.
to_field 'online_item_count_is' do |record, accumulator, context|
  context.output_hash['online_item_count_is'] = nil
  accumulator << record.xpath('.//dao[not(starts-with(@role,"electronic-record"))]').count
end

# DUL CUSTOMIZATION: wrap carrier extents in parentheses per DACS:
# https://saa-ts-dacs.github.io/dacs/06_part_I/03_chapter_02/05_extent.html#multiple-statements-of-extent
to_field 'extent_ssm' do |record, accumulator, context|
  context.output_hash['extent_ssm'] = nil
  physdescs = record.xpath('/ead/archdesc/did/physdesc')
  extents_per_physdesc = physdescs.map do |physdesc|
    extents = physdesc.xpath('./extent').map do |e|
      if e.attributes['altrender']&.value == 'carrier'
        "(#{e.text.strip})"
      else
        e.text.strip
      end
    end

    # Join extents within the same physdesc with an empty string
    extents.join(' ') unless extents.empty?
  end

  # Add each physdesc separately to the accumulator
  accumulator.concat(extents_per_physdesc)
end

to_field 'extent_tesim' do |_record, accumulator, context|
  context.output_hash['extent_tesim'] = nil
  accumulator.concat context.output_hash['extent_ssm'] || []
end

# DUL CUSTOMIZATION: add high component position to collection so the collection record
# appears after all components. Default was 0
to_field 'sort_isi' do |_record, accumulator, context|
  context.output_hash['sort_isi'] = nil
  accumulator << 999_999
end

# DUL CUSTOMIZATION: exclude repository/corpname since it's always Rubenstein.
# The first_iteration flag is a bit of a hack but when we blank out the values
# collected via the core config, we only want to do it on the first iteration
# else we would also be blanking out the values collected from this config.
name_first_iteration = true
NAME_ELEMENTS.map do |selector|
  to_field 'names_ssim', extract_xpath("//#{selector}[not(parent::repository)]"),
           unique do |_record, accumulator, context|
    # clear out the value collected via the core config
    context.output_hash['names_ssim'] = nil if name_first_iteration
    accumulator.map!
  end

  to_field "#{selector}_ssim", extract_xpath("//#{selector}[not(parent::repository)]"),
           unique do |_record, accumulator, context|
    # clear out the value collected via the core config
    context.output_hash["#{selector}_coll_ssim"] = nil if name_first_iteration
    accumulator.map!
  end
  name_first_iteration = false
end

# DUL CUSTOMIZATION: separate language vs langmaterial fields that don't have language
# Probably just a DUL modification; mix of conventions in use in our data
to_field 'language_ssim', extract_xpath('/ead/archdesc/did/langmaterial/language') do |_record, accumulator, context|
  # clear out the value collected via the core config
  context.output_hash['language_ssim'] = nil
  accumulator.map!
end

to_field 'langmaterial_ssim', extract_xpath('/ead/archdesc/did/langmaterial[not(descendant::language)]')
