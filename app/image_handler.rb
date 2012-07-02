#!/usr/bin/env ruby
# encoding: UTF-8
# Lines are usually wrapped to 72 characters, but can occasionally be as
# long as 108.

require 'tempfile' # For Dir.tmpdir
require 'fileutils'
require 'flickraw'
require 'RMagick' # Make case-sensitive filesytems happy.

module FTServer
  class InternalError < Exception
  end

  class NoSuchFlickrPhotoID < Exception
  end

  # This is the kind of thing one writes every six months, it seems.
  class MyTempDir
    attr_reader :path

    def initialize
      @path = File.join(Dir.tmpdir, "ftserver_image_#{Time.now.to_i}_#{rand(1048576)}")
      Dir.mkdir(@path)
    end

    # Housekeeping
    def delete
      FileUtils.rmtree(@path)
    end
  end

  class ImageHandler
    attr_reader :tempdir

    def initialize
      @tempdir = MyTempDir.new
      keyfile = File.open('config/flickr-keys.json', 'r')
      @key = JSON::load(keyfile)
      keyfile.close
      FlickRaw.api_key = @key['api_key']
      FlickRaw.shared_secret = @key['shared_secret']
      @flickr = FlickRaw::Flickr.new
      @flickr_photos = @flickr.photos
    end

    def retrieve(id)
      begin
        sizes = @flickr_photos.getSizes(:photo_id => id)
      rescue FlickRaw::FailedResponse
        raise NoSuchFlickrPhotoID.new("No such Flickr photo id: #{id}.")
      end
      sizes.each do |size|
        if size['label'] == "Medium 800"
          @source = size['source']
        end
      end

      # TODO: check if width is 600 or less; otherwise scaling won’t be
      # by 1/2 exactly.

      @source = sizes.last['source'] unless @source # Should be the largest available

      pwd = FileUtils.pwd
      FileUtils.chdir(@tempdir.path)
      # We use curl.
      origfilename = "flickr_image_original.jpg" # Note: not necessarily JPEG!
      retvalue = `curl "#{@source}" >"#{origfilename}"`
      unless File.file?(origfilename)
        raise InternalError.new("Could not retrieve photo from Flickr.")
      end
      FileUtils.chdir(pwd)
    end

    def transform(text = nil)
      pwd = FileUtils.pwd
      FileUtils.chdir(@tempdir.path)

      original = Magick::Image.read('flickr_image_original.jpg').first # TODO test rest of the array

      # Scale to 400x300, fitting image to that size (i. e. not cropping).
      new_image = original.resize_to_fit(400, 300)

      # Overlay text if application
      if text and text.length > 0
        new_image.annotate(Magick::Draw.new, 0, 0, 0, 0, text) do
          self.gravity = Magick::SouthEastGravity # Bottom right corner
          self.fill = 'white'
          self.pointsize = 18
        end
      end

      new_image.write('flickr_image_new.jpg')

      FileUtils.chdir(pwd)
      puts "Path:\n#{@tempdir.path}"
    end

    # Cleanup (call MyTempDir.delete, at least).
  end
end
