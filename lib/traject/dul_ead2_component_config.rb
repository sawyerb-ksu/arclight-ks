# frozen_string_literal: true

# This file holds DUL customizations to component-level
# EAD2002 indexing rules specified in ArcLight core.
# See: https://github.com/projectblacklight/arclight/blob/main/lib/arclight/traject/ead2_component_config.rb

# Note that to override any existing rules from core, we need to redefine them and
# blank out the result of the core indexing like this:
# context.output_hash['some_field_ssim'] = nil

require 'arclight'
require_relative '../dul_arclight/digital_object'
require_relative 'dul_arclight/dul_compressed_reader'

settings do
  provide 'component_traject_config', __FILE__
  # DUL Customization: Swap out Arclight::Traject::NokogiriNamespacelessReader with
  # custom DulCompressedReader to remove namespaces AND squish unwanted whitespace.
  provide 'reader_class_name', 'DulArclight::DulCompressedReader'
end

load_config_file(File.expand_path("#{Arclight::Engine.root}/lib/arclight/traject/ead2_component_config.rb"))

# DUL CUSTOMIZATION: Remove deprecated parent_ssim field. This field became
# deprecated in v1.1.4 but is still being indexed via the core config.
# https://github.com/projectblacklight/arclight/commit/e217957bd94cd0dcaae4fdf80316e39a530d99e8
to_field 'parent_ssim' do |_record, _accumulator, context|
  context.output_hash['parent_ssim'] = nil
end

# DUL CUSTOMIZATION: Separate/additional indexing treatment for these fields
# on the component level beyond how they are handled as SEARCHABLE_NOTES in
# core config. We have highly customized features for capturing/presenting
# access & use restrictions.
RESTRICTION_FIELDS = %w[
  accessrestrict
  userestrict
  phystech
].freeze

# DUL CUSTOMIZATION: Get title with formatting tags intact
to_field 'title_html_ssm', extract_xpath('./did/unittitle', to_text: false)

# DUL CUSTOMIZATION: Get normalized title with formatting tags intact
to_field 'normalized_title_html_ssm' do |_record, accumulator, context|
  title = context.output_hash['title_html_ssm']&.first&.to_s
  date = context.output_hash['normalized_date_ssm']&.first
  accumulator << settings['title_normalizer'].constantize.new(title, date).to_s
end

# DUL CUSTOMIZATION: redefine component <accessrestrict> & <userestrict> as own values OR values from
# the nearest non-collection ancestor that has these values.
RESTRICTION_FIELDS.map do |selector|
  to_field "#{selector}_html_tesm",
           extract_xpath("./#{selector}/*[local-name()!='head']",
                         to_text: false) do |_record, accumulator, context|
    # Clear the value captured via the core config
    context.output_hash["#{selector}_html_tesm"] = nil
    accumulator.map!(&:to_html)
  end

  # Capture closest ancestor's restrictions BUT only under these conditions:
  # 1) the component doesn't have its own restrictions
  # 2) the ancestor is in the <dsc> (i.e., not top-level)
  to_field "#{selector}_html_tesm",
           extract_xpath("./ancestor::*[#{selector}][ancestor::dsc][position()=1]/#{selector}/*[local-name()!='head']",
                         to_text: false) do |_record, accumulator, context|
    accumulator.map!(&:to_html)
    accumulator.replace [] if context.output_hash["#{selector}_html_tesm"].present?
  end

  to_field "#{selector}_tesim" do |_record, accumulator, context|
    # Clear the value captured via the core config
    context.output_hash["#{selector}_tesim"] = nil
    accumulator.concat context.output_hash["#{selector}_html_tesm"] || []
  end
end

# DUL CUSTOMIZATION: redefine parent as top-level collection <accessrestrict>
to_field 'parent_access_restrict_tesm' do |_record, accumulator, context|
  # Clear the value captured via the core config
  context.output_hash['parent_access_restrict_tesm'] = nil
  accumulator.concat settings[:root].output_hash['accessrestrict_html_tesm'] || []
end

# DUL CUSTOMIZATION: redefine parent as top-level collection <userestrict>
to_field 'parent_access_terms_tesm' do |_record, accumulator, context|
  # Clear the value captured via the core config
  context.output_hash['parent_access_terms_tesm'] = nil
  accumulator.concat settings[:root].output_hash['userestrict_html_tesm'] || []
end

# DUL CUSTOMIZATION: redefine parent as top-level collection <phystech>
to_field 'parent_access_phystech_tesm' do |_record, accumulator, context|
  # Clear the value captured via the core config
  context.output_hash['parent_access_phystech_tesm'] = nil
  accumulator.concat settings[:root].output_hash['phystech_html_tesm'] || []
end

# DUL CUSTOMIZATION: capture DUL-concocted collection-level global alert banner even for
# components. TODO: Unsure why this value does not seem to be available to copy via
# settings[:root].output_hash like many other fields are. For now, we'll just use the
# same xpath as the collection-level indexing to get the value from the archdesc.
to_field 'accessrestrict_collection_banner_html_tesm',
         extract_xpath("/ead/archdesc/accessrestrict[head='banner' or head='Banner']/*[local-name()!='head']",
                       to_text: false)

# DUL CUSTOMIZATION: Bib ID (esp. for request integration & catalog links)
to_field 'bibnum_ssim',
         extract_xpath('/ead/eadheader/filedesc/notestmt/note/p/num[@type="aleph" or @type="bibnum"]')

# DUL CUSTOMIZATION: Remove genreform (Format) from being grouped in with Subject.
# We make a separate facet for Format. ArcLight core also captures access_subjects_ssm
# but that appears to be unused.
to_field 'access_subjects_ssim', extract_xpath('./controlaccess', to_text: false) do |_record, accumulator, context|
  context.output_hash['access_subjects_ssim'] = nil
  accumulator.map! do |element|
    %w[subject function occupation].map do |selector|
      element.xpath(".//#{selector}").map(&:text)
    end
  end.flatten!
end

to_field 'access_subjects_ssm' do |_record, accumulator, context|
  context.output_hash['access_subjects_ssm'] = nil
  accumulator.concat Array.wrap(context.output_hash['access_subjects_ssim'])
end

# DUL CUSTOMIZATION: Add Format field, separate from Subject.
to_field 'genreform_ssim', extract_xpath('./controlaccess/genreform')

# DUL CUSTOMIZATION: use DUL rules for Digital Objects (esp. see role & xpointer)
to_field 'digital_objects_ssm', extract_xpath('./dao|./did/dao', to_text: false) do |_record, accumulator, context|
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

# DUL CUSTOMIZATION: wrap carrier extents in parentheses per DACS:
# https://saa-ts-dacs.github.io/dacs/06_part_I/03_chapter_02/05_extent.html#multiple-statements-of-extent
to_field 'extent_ssm' do |record, accumulator, context|
  context.output_hash['extent_ssm'] = nil
  physdescs = record.xpath('./did/physdesc')
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

# DUL CUSTOMIZATION: count all online access DAOs from this level down; omit the
# electronic-record ones as they are not really online access.
to_field 'total_digital_object_count_isim' do |record, accumulator|
  accumulator << record.xpath('.//dao[not(starts-with(@role,"electronic-record"))]').count
end

# DUL CUSTOMIZATION: separate language vs langmaterial fields that don't have language
# Probably just a DUL modification; mix of conventions in use in our data
to_field 'language_ssim', extract_xpath('./did/langmaterial/language') do |_record, accumulator, context|
  # clear out the value collected via the core config
  context.output_hash['language_ssim'] = nil
  accumulator.map!
end

to_field 'langmaterial_ssim', extract_xpath('./did/langmaterial[not(descendant::language)]')
