require 'open-uri'

module ApplicationHelper
  def format_time(time:, timezone: '')
    timezone = ENV["TZ"] if timezone.blank?
    I18n.l time.in_time_zone(timezone), format: :short
  end

  def download_avatar(username:, image_url:)
    file = Rails.root.join("tmp", "#{username}.png")
    if File.exist?(file)
      p "Skipped avatar " + username
      return false
    else
      File.open(file, "w") do |f|
        puts "#{username}: #{image_url}"
        IO.copy_stream(open(image_url), f)
      end
      p "Downloaded avatar " + username
      return true
    end
  end

  def remove_avatar_cache(username:)
    file = Rails.root.join("tmp", "#{username}.png")
    File.delete(file) if File.exist?(file)
  end

end
