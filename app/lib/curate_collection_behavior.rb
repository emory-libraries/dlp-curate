# frozen_string_literal: true

module CurateCollectionBehavior
  # Hyrax v3.4.2 Override: reverting back to the non-Valkrie processing because
  #   setting `member_of_collection_ids` in the Valkyrie-converted work object doesn't
  #   communicate back to the AF object to persist the same value there.
  def add_member_objects(new_member_ids)
    Array(new_member_ids).collect do |member_id|
      member = Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: member_id, use_valkyrie: false)
      message = Hyrax::MultipleMembershipChecker.new(item: member).check(collection_ids: id, include_current_members: true)
      if message
        member.errors.add(:collections, message)
      else
        member.member_of_collections << self
        member.save!
      end
      member
    end
  end

  def assign_id
    service.mint + Rails.configuration.x.curate_template
  end

  private

    def service
      @service ||= Noid::Rails::Service.new
    end
end
