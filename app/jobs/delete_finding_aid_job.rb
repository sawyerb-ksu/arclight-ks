# frozen_string_literal: true

# Delete a finding aid and all of its components from the index using the EADID slug
class DeleteFindingAidJob < ApplicationJob
  queue_as :delete

  def perform(eadid)
    Blacklight.default_index.connection.delete_by_query("_root_:#{eadid}")
    Blacklight.default_index.connection.commit
  end
end
