viddler-download
================

In light of [Viddler's announcement to close personal accounts](http://blog.viddler.com/djsteen/removal-of-personal-accounts/), I put together this script to download all of your videos, along with simple metadata about each video.

How To Use
----------

1. Make sure you have Ruby and Bundler installed
2. Download or clone this repo
3. Run `bundle install` in this directory
4. Modify the `api_key`, `username`, and `password` variables in the `download.rb` file as appropriate for your Viddler account.
5. Run `ruby download.rb`

All of the videos will be downloaded to the `videos/` directory, and each video will be in its own folder. In each folder, you'll find all of the files that could be downloaded and a `details.json` file, which contains the result of the `viddler.videos.getDetails` API call. Any video file that can't be downloaded will be skipped, and an error message will be printed.

**NOTE:** If the download permission of a video file is set to anything other that "public", it will be temporarily switched to "public" so the files can be downloaded. After downloading, it will be switched back to its previous value. There might be a better way to deal with private videos, but I couldn't find it.
