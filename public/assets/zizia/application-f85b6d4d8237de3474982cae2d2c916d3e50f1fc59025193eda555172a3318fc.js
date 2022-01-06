define('zizia/DisplayUploadedFile', ['exports', 'module'], function (exports, module) {
  'use strict';

  var _createClass = (function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ('value' in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; })();

  function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError('Cannot call a class as a function'); } }

  var DisplayUploadedFile = (function () {
    function DisplayUploadedFile() {
      _classCallCheck(this, DisplayUploadedFile);

      this.regexp = /[^a-zA-Z0-9\.\-\+_]/g;
    }

    _createClass(DisplayUploadedFile, [{
      key: 'replaceWhitespace',
      value: function replaceWhitespace(input) {
        return input.replace(this.regexp, '_');
      }
    }, {
      key: 'requiresEscape',
      value: function requiresEscape(input) {
        return this.regexp.test(input);
      }
    }, {
      key: 'displayReplaceMessage',
      value: function displayReplaceMessage(input) {
        if (this.requiresEscape(input)) {
          return '<b> Note: </b> Your file name contained spaces, which have been replaced by underscores.\nThis will have no effect on your import.';
        } else {
          return '';
        }
      }
    }, {
      key: 'display',
      value: function display() {
        var fileInput = document.querySelector('#file-upload');
        var files = fileInput.files;
        for (var i = 0; i < files.length; i++) {
          var file = files[i];
          document.querySelector('#file-upload-display').innerHTML = '\n<div class="row">\n  <div class="col-md-12">\n    <div class="well style="\n         background-color: #dff0d8;\n         border-color: #d6e9c6;\n         color: #3c763d;">\n      <p>You sucessfully uploaded this CSV: <b> ' + this.replaceWhitespace(file.name) + ' </b>\n      </p>\n      ' + this.displayReplaceMessage(file.name) + '\n      <p>\n    </div>\n  </div>\n</div>';
        }
      }
    }]);

    return DisplayUploadedFile;
  })();

  module.exports = DisplayUploadedFile;
});
var Zizia = {
  displayUploadedFile: function () {
    var DisplayUploadedFile = require('zizia/DisplayUploadedFile')
    new DisplayUploadedFile().display()
  },
  checkStatuses: function (options) {
    var results = []
    // Go through the list of thumbnails for the work based
    // on the deduplicationKey
    options.thumbnails.forEach(function (thumbnail) {
      $.ajax({
        type: 'HEAD',
        url: thumbnail,
        complete: function (xhr) {
          // Request only the headers from the thumbnail url
          // push the statuses into an array
          results.push(xhr.getResponseHeader('status'))
          // See how many urls are not returning 200
          var missingThumbnailCount = results.filter(
            function (status) {
              if (status !== '200 OK') { return true }
            }).length
          // If there are any not returning 200, the work is still being processed
          if (missingThumbnailCount > 0) {

          } else {
            Zizia.addSuccessClasses(options)
          }
        }
      })
    })
  },
  displayWorkStatus: function () {
    $('[id^=work-status]').each(function () {
	    var deduplicationKey = $(this)[0].id.split('work-status-')[1]
	    $.get('/pre_ingest_works/thumbnails/' + deduplicationKey, function (data) {
        data.deduplicationKey = deduplicationKey
        Zizia.checkStatuses(data)
      })
    })
  },
  addSuccessClasses: function (options) {
    $('#work-status-' + options.deduplicationKey + ' > span').removeClass('status-unknown')
    $('#work-status-' + options.deduplicationKey + ' > span').removeClass('glyphicon-question-sign')
    $('#work-status-' + options.deduplicationKey + ' > span').addClass('text-success')
    $('#work-status-' + options.deduplicationKey + ' > span').addClass('glyphicon-ok-sign')
  }
}
;
// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//

;
