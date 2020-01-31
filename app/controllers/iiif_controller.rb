class IiifController < ApplicationController


  def show
    @url = "http://127.0.0.1:8182/iiif/2/river_with_jam.jpg/full/full/0/default.jpg"
    send_data HTTP.get(@url).body, type: 'image/jpeg', :x_sendfile => true, disposition: 'inline'
  end
end
