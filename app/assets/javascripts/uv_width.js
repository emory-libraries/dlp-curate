$(document).on('turbolinks:load', function() {
  $('#universal-viewer-iframe').width($('.view-wrapper').width())

  $(window).on('resize', function(){
    $('#universal-viewer-iframe').width($('.view-wrapper').width())
  })
})