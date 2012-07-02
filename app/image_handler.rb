#!/usr/bin/env ruby
# encoding: UTF-8
# Lines are usually wrapped to 72 characters, but can occasionally be as
# long as 108.

require 'tempfile' # For Dir.tmpdir
require 'fileutils'
require 'flickraw'
require 'RMagick' # Make case-sensitive filesystems happy.

module FTServer
  class InternalError < Exception
  end

  # This is the kind of thing one writes every six months, it seems.
  class MyTempDir
    attr_reader :path

    def initialize
      @path = File.join(Dir.tmpdir, "scale_flickr_#{Time.now.to_i}_#{rand(1048576)}")
      Dir.mkdir(@path)
    end

    # Housekeeping
    def delete
      FileUtils.rmtree(@path)
    end
  end

  class ImageHandler
    attr_reader :tempdir # For tests only FIXME

    def initialize
      @tempdir = MyTempDir.new
      keyfile = File.open('config/flickr-keys.json', 'r')
      @key = JSON::load(keyfile)
      keyfile.close
      FlickRaw.api_key = @key['api_key']
      FlickRaw.shared_secret = @key['shared_secret']
      @flickr = FlickRaw::Flickr.new # TODO API keys
      @flickr_photos = @flickr.photos
    end

    def retrieve(id)
      # TODO something if photo_id invalid
      sizes = @flickr_photos.getSizes(:photo_id => id)
      sizes.each do |size|
        if size['label'] == "Medium 800"
          @source = size['source']
        end
      end

      # TODO: check if width is 600 or less; otherwise scaling won’t be
      # by 1/2 exactly.

      @source = sizes.last['source'] unless @source # Should be the largest available

      # Convention: only ‘retrieve’ chdir’s to the temporary directory. # FIXME That’s not realistic
      pwd = FileUtils.pwd
      FileUtils.chdir(@tempdir.path)
      # We use curl.
      origfilename = "flickr_image_original.jpg" # Note: not necessarily JPEG!
      retvalue = `curl "#{@source}" >"#{origfilename}"`
      puts "retvalue is #{retvalue}"
      # TODO Ruby seems to not know about that.
      unless File.file?(origfilename)
        raise InternalError.new("Could not retrieve photo from Flickr.")
      end
      FileUtils.chdir(pwd)
    end

    def transform(text = nil)
      pwd = FileUtils.pwd
      FileUtils.chdir(@tempdir.path)

      puts "Hello I’m in #{FileUtils.pwd}"
      original = Magick::Image.read('flickr_image_original.jpg').first # TODO test rest of the array

      # Scale to 400x300, fitting image to that size (i. e. not cropping).
      new_image = original.resize_to_fit(400, 300)

      # Overlay text if application
      if text and text.length > 0
        # FIXME No idea what to do with the draw object here.
        new_image.annotate(Magick::Draw.new, 0, 0, 0, 0, text) do # TODO better placement
          self.gravity = Magick::SouthEastGravity # Bottom right corner
          self.fill = 'white' # TODO some transparency?
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
