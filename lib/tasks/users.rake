namespace :users do

  desc "Updating all users from Slack"
  task :update_from_slack => :environment do
    include ApplicationHelper

    # Update/create members from Slack
    raw = Net::HTTP.get(URI("https://slack.com/api/users.list?presence=false&token=" + ENV["SLACK_TOKEN"]))
    json = JSON.parse(raw)
    members = json['members']
    members.each do |m|
      next if m['deleted'] || m['is_bot'] || m['is_ultra_restricted'] # Skip bots & guests
      uid = m['id']
      user = User.find_by_external_id(uid)
      user = User.new(external_id: uid) if !user
      user.username     = uid
      user.display_name = m['profile']['display_name']
      user.email        = m['profile']['email']
      user.avatar_url   = m['profile']['image_48']
      if user.avatar_hash != m['profile']['avatar_hash']
        user.avatar_hash = m['profile']['avatar_hash']
        remove_avatar_cache(username: user.username)
      end
      p "#{user.username} - #{user.display_name}" if user.save!
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