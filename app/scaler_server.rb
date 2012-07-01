#!/usr/bin/env ruby
# encoding: UTF-8

require 'rack'
require 'rack/request'
require 'rack/response'
require 'scale-flickr'

class ScalerServer
  def call(env)
    datadir = File.join(File.dirname(File.realpath(__FILE__)), '..', 'data') # TODO configure

    req = Rack::Request.new(env)

    request_path = env['PATH_INFO'] # TODO Why doesn’t REQUEST_PATH work?
    if request_path =~ /\A\/images\/(.*)\z/
      response = Rack::Response.new([], 200, { 'Content-Type' => 'image/jpeg' })

      image_filename = $1
      filepath = File.join(datadir, image_filename)
      image_file = File.open(filepath, 'r')
      response.write(image_file.read(File.size(filepath)))
      image_file.close

      response.close
    else
      response = Rack::Response.new([], 200, { 'Content-Type' => 'text/html' })

      id = req.GET['flickr_id']
      text = req.GET['text']

      if id
        value = "Flickr ID #{req.GET['flickr_id']}"
        if text
          value = value + " with overlaid text “#{}”"
        end
      else
        value = "Please include a Flickr photo ID in your GET request"
      end

      scaler = FlickrScaler::Scaler.new
      scaler.retrieve(id)
      scaler.transform(text)
      new_id = Time.now.to_i.to_s
      new_filename = new_id + ".jpg"
      FileUtils.cp(File.join(scaler.tempdir.path, 'flickr_image_new.jpg'), File.join(datadir, new_filename))
      # scaler.tempdir.delete # Not yet.

      value += "<p>http://#{env['SERVER_NAME']}/images/#{new_filename}<p>"

      response.write('<title>Flickr Scaler Server</title>')
      response.write("<p>#{value}</p>")

      response.close
    end

    response.finish
  end
end
