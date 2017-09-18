namespace :users do

  desc "Updating all users from Slack"
  task :update_from_slack => :environment do
    include ApplicationHelper

    # Update/create members from Slack
    raw = Net::HTTP.get(URI("https://slack.com/api/users.list?presence=false&token=" + ENV["SLACK_TOKEN"]))
    json = JSON.parse(raw)
    members = json['members']
    members.each do |m|
      # Ignore records with no update in last 24 hours
      next if (Time.now-Time.at(m['updated'].to_i)) > 24*3600

      # Ignore non-active users & guests & bot
      user = User.find_or_initialize_by(external_id: m['id'])
      user.active       = !(m['deleted'] || m['is_bot'] || m['is_ultra_restricted']) 
      next if !user.active && !user.persisted?

      user.username     = m['profile']['display_name'] || m['id'] # display_name from slack might be null
      user.display_name = m['profile']['real_name']
      user.email        = m['profile']['email']
      user.avatar_url   = m['profile']['image_48']
      if user.avatar_hash != m['profile']['avatar_hash']
        user.avatar_hash = m['profile']['avatar_hash']
        remove_avatar_cache(username: user.username)
      end

      if user.save
        p "#{user.username} - #{user.display_name} - SAVED"
      else
        p "#{user.username} - #{user.display_name} - ERROR"
        ap user.errors.full_messages
        ap m
      end
    end
  end

  desc "Download avatars for all users, skipping existing ones"
  task :download_avatars => :environment do
    include ApplicationHelper
    dir = Rails.root.join("tmp")
    Dir.mkdir dir if !Dir.exist? dir
    User.all.each do |u|
      download_avatar(username: u.username, image_url: u.avatar_url)
    end
  end

  desc "Reset monthly allowance"
  task :reset_monthly_allowance => :environment do
    User.update_all(allowance: ENV["DEFAULT_ALLOWANCE"]) # only active users, default scope
  end

end