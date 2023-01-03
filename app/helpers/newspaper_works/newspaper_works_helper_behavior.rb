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
    # rubocop:disable Rails/OutputSafety
    def render_ocr_snippets(options = {})
      snippets = options[:value]
      snippets_content = [tag.div("... #{snippets.first} ...".html_safe,
                                      class: 'ocr_snippet first_snippet')]
      if snippets.length > 1
        snippets_content << render(partial: 'catalog/snippets_more',
                                   locals:  { snippets: snippets.drop(1),
                                              options:  options })
      end
      snippets_content.join("\n").html_safe
    end
    # rubocop:enable Rails/OutputSafety
  end
end
