This is ftserver, the Flickr Transform server.

Copyright (c) Arthur Reutenauer, London, July 2012.

The files in this repository are available under the terms of the
Creative Common Attribution License (CC-BY), either version 3.0 thereof
or, at your option, any later version.  Version 3.0 is available at

	http://creativecommons.org/licenses/by/3.0/

Installation
===========

This program has been written in standard Ruby 1.9 with the help of some
libraries, and has been tested with Ruby 1.9.1 on Ubuntu 10.10, and Ruby
1.9.2 on Mac OS 10.6.  It uses bundler to provide the necessary
libraries.

Therefore, it should be enough to run:

1. git clone https://github.com/reutenauer/ftserver.git
2. Copy your Flickr API keys to config/flickr-keys.json in the format defined there.
   (the API key should be called “api_key,” and the secret key “shared_secret”)
3. Run bundle install
4. Start the server from the top-level directory with:

	bundle exec ruby -Iapp start-server

The service is then available on http://localhost:48067/

See section “Usage” below for usage notes, and examples.

Note: On Linux, I’ve found that it was necessary to install the Ubuntu /
Debian packages ruby1.9.1-dev and libmagickwand-dev (I installed
libmagickcore-dev first, but I’m not sure this was really needed).

Usage
=====

Send an HTTP GET request to http://<server>:<port>/?flickr_id=<id>&text=<overlay>
(the latter part being optional).  The server then serves an HTML page
containing the link to the scaled image, with the text overlaid on the
bottom right corner if applicable.

Tests:

http://localhost:48067/?flickr_id=123 (invalid photo ID)
http://localhost:48067/?flickr_id=7460204746 (valid one)
http://localhost:48067/?flickr_id=7460204746&text=In%20the%20style%20Faberge (valid one plus text) – Alas, no UTF-8!
http://localhost:48067/images/7460204746_1341258930_473646.jpg (result of above request)

Notes on the architecture
=========================

The main code is in the directory app, with tests in spec for the
back-end methods (not the web service); and config contains, obviously,
configuration.  The tests use on picture available in sample.  The
result of the image transformations are in data.

The Ruby libraries I’ve used are:

- rack for the Web server;
- flickraw to access Flickr;
- rmagick for graphics;
- rspec for the tests of the main methods in image_handler.rb
