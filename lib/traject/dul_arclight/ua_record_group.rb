# frozen_string_literal: true

module DulArclight
  ##
  # A utility class to return a human-readable UA record group label
  # from a YML config lookup file. This is used to create a hierarchical
  # facet via the blacklight-hierarchy gem, and other hierarchically-oriented
  # links to record groups.
  class UaRecordGroup
    # @param [String] `group`
    # @param [String] `subgroup`

    UA_RECORD_GROUPS = YAML.load_file('config/ua_record_groups.yml')

    def initialize(group: nil, subgroup: nil)
      @group = group
      @subgroup = subgroup
    end

    def label
      if @subgroup.present?
        "#{@group} -- #{group_label} > #{@subgroup} -- #{subgroup_label}"
      else
        "#{@group} -- #{group_label}"
      end
    end

    def group_label
      UA_RECORD_GROUPS.dig(@group, 'title') || 'Unknown Group'
    end

    def subgroup_label
      UA_RECORD_GROUPS.dig(@group, 'subgroups', @subgroup, 'title') || 'Unknown Subgroup'
    end

    private

    attr_reader :group, :subgroup
  end
end
