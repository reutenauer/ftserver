#!/usr/bin/env ruby
# encoding: UTF-8

require 'rack'
require 'rack/request'
require 'rack/response'
require 'image_handler'

module FTServer
  class Server
    def call(env)
      datadir = File.join(File.dirname(File.realpath(__FILE__)), '..', 'data') # TODO configure

      req = Rack::Request.new(env)

      if env['REQUEST_METHOD'] == 'GET' # We support only that method.
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

          handler = ImageHandler.new
          handler.retrieve(id)
          handler.transform(text)
          new_id = Time.now.to_i.to_s
          new_filename = new_id + ".jpg"
          FileUtils.cp(File.join(handler.tempdir.path, 'flickr_image_new.jpg'), File.join(datadir, new_filename))
          # handler.tempdir.delete # Not yet.

          value += "<p>http://#{env['SERVER_NAME']}/images/#{new_filename}<p>"

          response.write('<title>Flickr Scaler Server</title>')
          response.write("<p>#{value}</p>")

          response.close
        end
      end

      response.finish if response
    end
  end
end
