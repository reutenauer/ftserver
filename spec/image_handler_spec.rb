#!/usr/bin/env ruby
# encoding: UTF-8

require 'image_handler'
require 'fileutils'

include FTServer

describe ImageHandler do
  let(:sample_dir) { File.join(File.dirname(File.realpath(__FILE__)), '..', 'sample') }
  let(:bird_and_bell) { File.join(sample_dir, '7460204746_155b4ceb8e_c.jpg') }

  describe '#initialize' do
    it 'does not fail' do
      image_handler = ImageHandler.new
    end
  end

  describe '#retrieve' do
    it 'retrieves' do
      image_handler = ImageHandler.new
      image_handler.retrieve(7460204746)
      File.file?(File.join(image_handler.tempdir.path, "flickr_image_original.jpg")).should == true
    end
  end

  describe '#transform' do
    it 'transforms' do
      image_handler = ImageHandler.new
      FileUtils.cp(bird_and_bell, File.join(image_handler.tempdir.path, 'flickr_image_original.jpg'))
      image_handler.transform('In the style of Fabergé ...')
      File.file?(File.join(image_handler.tempdir.path, 'flickr_image_new.jpg')).should == true
    end
  end
end
