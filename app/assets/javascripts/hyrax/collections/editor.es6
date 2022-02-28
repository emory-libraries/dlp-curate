// [Hyrax-overwrite v3.3.0] Adds autocomplete
import ThumbnailSelect from 'hyrax/thumbnail_select'
import Participants from 'hyrax/admin/admin_set/participants'
import tabifyForm from 'hyrax/tabbed_form'
import Autocomplete from 'hyrax/autocomplete'

// Controls the behavior of the Collections edit form
// Add search for thumbnail to the edit descriptions
export default class {
  constructor(elem) {
    let field = elem.find('#collection_thumbnail_id')
    this.thumbnailSelect = new ThumbnailSelect(this.url(), field)
    tabifyForm(elem.find('form.editor'))

    let participants = new Participants(elem.find('#participants'))
    participants.setup()
  }

  url() {
    let urlParts = window.location.pathname.split("/")
    urlParts[urlParts.length - 1] = "files"
    return urlParts.join("/") 
  }

  init() {
    this.autocomplete()
  }

  autocomplete() {
    var autocomplete = new Autocomplete()

	$('[data-autocomplete]').each((function() {
	  var elem = $(this)
	  autocomplete.setup(elem, elem.data('autocomplete'), elem.data('autocompleteUrl'))
	}))

	$('.multi_value.form-group').manage_fields({
	  add: function(e, element) {
	    var elem = $(element)
	    // Don't mark an added element as readonly even if previous element was
	    // Enable before initializing, as otherwise LinkedData fields remain disabled
	    elem.attr('readonly', false)
	    autocomplete.setup(elem, elem.data('autocomplete'), elem.data('autocompleteUrl'))
	  }
	})
  }
}
