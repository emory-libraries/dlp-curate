# frozen_string_literal: true

# [Hyrax-overwrite-v3.3.0] overrides the child_nesting_depth method because child
# will now arrive as `false` from calling method `valid_combined_nesting_depth?'.
# This is a bug from the Samvera side.
Hyrax::Collections::NestedCollectionQueryService.module_eval do
  def self.child_nesting_depth(child:, scope:)
    return 1 if child.blank?
    builder = Hyrax::SearchBuilder.new(scope).with(
      {
        q:    "#{Samvera::NestingIndexer.configuration.solr_field_name_for_storing_pathnames}:/.*#{child.id}.*/",
        sort: "#{Samvera::NestingIndexer.configuration.solr_field_name_for_deepest_nested_depth} desc"
      }
    )
    builder.rows = 1
    query = clean_lucene_error(builder: builder)
    response = scope.repository.search(query).documents.first

    descendant_depth = response[Samvera::NestingIndexer.configuration.solr_field_name_for_deepest_nested_depth]

    child_depth = NestingAttributes.new(id: child.id, scope: scope).depth
    nesting_depth = descendant_depth - child_depth + 1

    nesting_depth.positive? ? nesting_depth : 1
  end
end
