# Pin npm packages by running ./bin/importmap

pin "bootstrap", to: "bootstrap.js", preload: true # @4.6.2
pin "jquery" # @4.0.0
pin "popper.js" # @1.16.1
pin "datatables.net-bs4" # @2.3.8
pin "datatables.net" # @2.3.8
pin "datatables.net-searchpanes-bs4" # @2.3.5
pin "datatables.net-searchpanes" # @2.3.5
pin "datatables.net-select-bs4" # @3.1.3
pin "datatables.net-select" # @3.1.3
pin "nearley" # @2.20.1
pin "edtf" # @4.11.0
pin "handlebars" # @4.7.9
pin "jquery-validation" # @1.22.1
pin "rails-ujs" # @5.2.8
pin "corejs-typeahead" # @1.3.4
pin "almond" # @0.3.3

pin "blacklight", to: "blacklight/blacklight.js"
pin "blacklight_gallery", to: "blacklight_gallery/default.js"
pin "hyrax", to: "application.js"
pin "bulkrax", to: "bulkrax/application.js"

pin "application"

pin "custom/bulkrax/datatables"
pin "custom/hyrax/autocomplete/default"
pin_all_from "app/javascript/custom/hyrax/collections", under: "custom_hyrax_collections"

