require 'rubygems'
require 'bundler/setup'

require 'viddler-ruby'
require 'open-uri'
require 'json'

###########################################
# MAKE SURE TO CHANGE THE VARIABLES BELOW #
###########################################
api_key = "API_KEY_HERE"
username = "USERNAME_HERE"
password = "PASSWORD_HERE"

# Don't change past here

viddler = Viddler::Client.new(api_key)
viddler.authenticate!(username, password)

page = 1

puts "Getting video details"
video_details = []

while true
  response = viddler.get('viddler.videos.getByUser', per_page: 100, page: page)

  videos = response['list_result']['video_list']

  break if videos.empty?

  response['list_result']['video_list'].each do |vid|
    video_details << viddler.get('viddler.videos.getDetails', video_id: vid['id'])
  end

  page += 1
end

puts "Retrieved details for #{video_details.length} videos, beginning download"

errors = []

video_details.each do |details|
  video = details['video']
  sanitized_title = video['title'].gsub(/[^\w\. ]/, '_')
  upload_date = Time.at(video['upload_time'].to_i).strftime("%Y-%m-%d %H-%M-%S")

  directory = "videos/#{upload_date} - #{sanitized_title} - #{video['id']}"
  FileUtils.mkdir_p(directory)

  # save API details output
  File.open "#{directory}/details.json", 'w' do |file|
    file.write(JSON.pretty_generate(details))
  end

  previous_download_perm = nil
  if video['permissions']['download']['level'] != 'public'
    puts "Temporarily enabling downloads for #{video['title']} (#{video['id']})"

    # authenticate again, in case the sessionid has expired
    viddler.authenticate!(username, password)

    previous_download_perm = video['permissions']['download']['level']
    viddler.post('viddler.videos.setDetails', download_perm: 'public', video_id: video['id'])

    # get the details again, since the video download link has changed
    details = viddler.get('viddler.videos.getDetails', video_id: video['id'])
    video = details['video']
  end

  # save actual files
  video['files'].each do |file|
    puts "Starting download of #{video['title']} (#{video['id']}) / #{file['profile_name']}.#{file['ext']}"

    filename = "#{directory}/#{file['id']} - #{file['profile_name']}.#{file['ext']}"

    begin
      open(file['url'], 'rb') do |read_file|
        File.open(filename, 'wb') do |write_file|
          write_file.write(read_file.read)
        end
      end
    rescue
      puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
      puts "Unable to download #{video['title']} (#{video['id']}) / #{file['profile_name']}.#{file['ext']}"
      puts "URL: #{file['url']}"
      puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

      errors << "Unable to download #{video['title']} (#{video['id']}) / #{file['profile_name']}.#{file['ext']}: #{file['url']}"
    end
  end

  if previous_download_perm
    puts "Reverting download permissions for #{video['title']} (#{video['id']}) back to #{previous_download_perm}"

    # authenticate again, in case the sessionid has expired
    viddler.authenticate!(username, password)
    viddler.post('viddler.videos.setDetails', download_perm: previous_download_perm, video_id: video['id'])
  end
end

puts "\n\n\n\n"
puts "Finished downloading videos"
puts "#{errors.count} errors"
errors.each {|error| puts error}