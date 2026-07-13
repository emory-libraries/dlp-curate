# frozen_string_literal: true
# gem 'newspaper_works', v1.0.2
# Refer to the gem repository for more details: https://github.com/samvera-labs/newspaper_works
# Released under license Apache License 2.0: https://github.com/samvera-labs/newspaper_works/blob/main/LICENSE
# This gem is not yet compatible with Hyrax v3, hence why I am only using the portions relevant to our use case
# This gem is used for keyword highlighting in search results

module NewspaperWorks
  module NewspaperWorksHelperBehavior
    ##
    # print the ocr snippets. if more than one, separate with <br/>
    #
    # @param options [Hash] options hash provided by Blacklight
    # @return [String] snippets HTML to be rendered
    def render_ocr_snippets(options = {})
      snippets = options[:value]
      snippets_content = [tag.div("... #{snippets.first} ...", class: 'ocr_snippet first_snippet')]
      if snippets.length > 1
        snippets_content << render(partial: 'catalog/snippets_more',
                                   locals:  { snippets: snippets.drop(1),
                                              options: })
      end

      full_text_no_emphasis_text(snippets) ? multiple_match_text(id: options[:document][:id]) : safe_join(snippets_content)
    end

    private

      def full_text_no_emphasis_text(snippets_array)
        snippets_array.length == 1 && !snippets_array.first.include?('<em>')
      end

      def multiple_match_text(id:)
        tag.div(
          safe_join(['Multiple matches found. Please ', work_show_page_link(id:), ' for more search options.']),
          class: 'ocr_snippet first_snippet'
        )
      end

      def work_show_page_link(id:)
        link_to('view the work file', hyrax_curate_generic_work_path(id))
      end
  end
end
