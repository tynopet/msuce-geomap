class GmapsController < ApplicationController

  def index
    
  end

  def create
    points = ActiveSupport::JSON.decode coord_params[:points]
    gmaps = GoogleMapsService::Client.new(key: 'AIzaSyB5R31J55ROl0TJVwd0jNQNOBhO9XK07mE')
    results = []
    points.each do |p|
      results.push gmaps.elevation(p)
    end
    File.open('public/markers.html', 'w') do |f|
      f.puts '<table border="1"><tr><th>Longitude</th><th>Lititude</th><th>Elevation</th></tr>'
      results.each do |r|
        f.puts('<tr><td>' + r[0][:location][:lng].to_s + '</td>')
        f.puts('<td>' + r[0][:location][:lat].to_s + '</td>')
        f.puts('<td>' + r[0][:elevation].to_s + '</td></tr>')
      end
      f.puts '</table>'
    end
    render :json => {success: 'yep'}
  end

  def download
    send_file "#{Rails.root}/public/markers.html"
  end

  private
    def coord_params
      params.permit(:points)
    end
end
