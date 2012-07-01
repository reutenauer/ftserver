#!/usr/bin/env ruby
# encoding: UTF-8

require 'scale-flickr'
require 'fileutils'

include FlickrScaler

describe Scaler do
  let(:sample_dir) { File.join(File.dirname(File.realpath(__FILE__)), '..', 'sample') }
  let(:bird_and_bell) { File.join(sample_dir, '7460204746_155b4ceb8e_c.jpg') }

  describe '#initialize' do
    it 'does not fail' do
      scaler = Scaler.new
    end
  end

  describe '#retrieve' do
    it 'retrieves' do
      scaler = Scaler.new
      scaler.retrieve(7460204746)
      File.file?(File.join(scaler.tempdir.path, "flickr_image_original.jpg")).should == true
    end
  end

  describe '#transform' do
    it 'transforms' do
      scaler = Scaler.new
      FileUtils.cp(bird_and_bell, File.join(scaler.tempdir.path, 'flickr_image_original.jpg'))
      scaler.transform('In the style of Fabergé ...')
      File.file?(File.join(scaler.tempdir.path, 'flickr_image_new.jpg')).should == true
    end
  end
end
