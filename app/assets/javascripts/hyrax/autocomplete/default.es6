// [Hyrax-overwrite] Adding response block for displaying request.term as a dynamic option
// This script initializes a jquery-ui autocomplete widget
export default class Default {
  constructor(element, url) {
    this.url = url;
    if (this.url !== undefined)
      element.autocomplete(this.options(element))
  }

  options(element) {
    return {
      minLength: 2,

      source: (request, response) => {
        $.getJSON(this.url, {
          q: request.term
        }, response );
      },

      response: function(event, ui) {
        // Add dynamic option (custom term) when no value from
        // external vocab matches search term
        if (ui.content.length === 0) {
          ui.content.push({label: $(this).val(), value: $(this).val()});
        }
      },

      focus: function() {
        // prevent value inserted on focus
        return false;
      },

      complete: function(event) {
        $('.ui-autocomplete-loading').removeClass("ui-autocomplete-loading");
      },

      select: function() {
        if (element.data('autocomplete-read-only') === true) {
          element.attr('readonly', true);
        }
      }
    }
  }
}
