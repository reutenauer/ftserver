#!/usr/bin/env ruby
# encoding: UTF-8

require 'rack'
require 'rack/request'
require 'rack/response'
require 'image_handler'

module FTServer
  class Server
    # The repository for our scaled pictures is under <root>/data
    @@datadir = File.join(File.dirname(File.realpath(__FILE__)), '..', 'data')

    # We support exactly two types of paths:
    # 1. The root path with a mandatory parameter ‘flickr_id’ and an
    #    optional ‘text’ (i. e. “/?flickr_id=123def&text=some%20caption”
    # 2. Paths such as  “/images/abc456.jpg” that serves a previously
    #    processed image.
    #
    # Type 1 paths are handled by the method “transform_image,” type 2 by
    # “serve_image.”

    # 404 in Roman numerals.
    def cdiv
      response = Rack::Response.new([], 404).close
    end

    def transform_image(env)
      request = Rack::Request.new(env)
      response = Rack::Response.new([], 200, { 'Content-Type' => 'text/html' })

      id = request.GET['flickr_id']
      text = request.GET['text']

      # user_message is the user-visible message we’ll display on the
      # HTML page we return.
      # We have at least three cases: the request contained a valid id;
      # an invalid id; no id at all.  The optional text is treated as
      # a subcase of the first one.

      if id # We have an id, the real wor begins.
        begin
          user_message = "Flickr ID #{request.GET['flickr_id']}"
          if text && text.length > 0 # We treat empty strings the same way as nils.
            user_message + " with overlaid text “#{request.GET['text']}”"
          end

          handler = ImageHandler.new
          handler.retrieve(id) # May raise an exception
          handler.transform(text)
          new_id = id.to_s + '_' + Time.now.to_i.to_s
          new_filename = new_id + '_' + rand(1048576).to_s + '.jpg'
          FileUtils.cp(File.join(handler.tempdir.path, 'flickr_image_new.jpg'), File.join(@@datadir, new_filename))
          # handler.tempdir.delete # Not yet.

          user_message += "<p>http://#{env['SERVER_NAME']}/images/#{new_filename}<p>"
        rescue NoSuchFlickrPhotoID => err
          user_message = err.message
        end
      else # if id
        user_message = "Please include a Flickr photo ID in your GET request"
      end

      response.write('<title>Flickr Scaler Server</title>')
      response.write("<p>#{user_message}</p>")
      response.close

      response
    end

    def serve_image(image_filename)
      begin
        response = Rack::Response.new([], 200, { 'Content-Type' => 'image/jpeg' })

        filepath = File.join(@@datadir, image_filename)
        image_file = File.open(filepath, 'r') # May raise exception
        response.write(image_file.read(File.size(filepath)))
        image_file.close
        response.close
      rescue Errno::ENOENT
        response = cdiv # 404
      end

      response
    end

    def call(env)
      # We support only GET requests for two very particular cases.
      # For all the rest, we return a 404 code.
      # That routing method is admittedly simplistic, but it does what
      # we need.
      if env['REQUEST_METHOD'] == 'GET' 
        request_path = env['PATH_INFO']
        if request_path =~ /\A?/
          response = transform_image(env)
        elsif request_path =~ /\A\/images\/(.*)\z/
          response = serve_image($1)
        end
      end

      # If the request is anything else than the above, return a 404.
      response ||= Rack::Response.new([], 404)
      response.finish
    end
  end
end
