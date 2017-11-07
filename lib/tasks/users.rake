namespace :users do
  def update_user(user_json)
    user = User.find_or_initialize_by(external_id: user_json['id'])
    user.active = !(user_json['deleted'] || user_json['is_bot'] || user_json['is_ultra_restricted'])
    return if !user.active && !user.persisted?

    user.username     = user_json['name'] || user_json['id'] # display_name from slack might be null
    user.display_name = user_json['profile']['real_name']
    user.avatar_url   = user_json['profile']['image_48']
    if user.avatar_hash != user_json['profile']['avatar_hash']
      user.avatar_hash = user_json['profile']['avatar_hash']
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

  def download_users_json
    raw = Net::HTTP.get(URI('https://slack.com/api/users.list?presence=false&token=' + ENV['SLACK_TOKEN']))
    JSON.parse(raw)
  end

  desc 'Fetch all slack users, usually this should be run only once'
  task fetch_all: :environment do
    json = download_users_json
    members = json['members']
    members.each do |m|
      update_user(m)
    end
  end

  desc 'Updating all users from Slack'
  task update_from_slack: :environment do
    json = download_users_json
    members = json['members']
    members.each do |m|
      # Ignore records with no update in last 24 hours
      next if (Time.now - Time.at(m['updated'].to_i)) > 24 * 3600

      update_user(m)
    end
  end

  desc 'Download avatars for all users, skipping existing ones'
  task download_avatars: :environment do
    include ApplicationHelper
    dir = Rails.root.join('tmp')
    Dir.mkdir dir unless Dir.exist? dir
    User.all.each do |u|
      download_avatar(username: u.username, image_url: u.avatar_url)
    end
  end

  desc 'Reset monthly allowance'
  task reset_monthly_allowance: :environment do
    User.update_all(allowance: ENV['DEFAULT_ALLOWANCE']) # only active users, default scope
  end
end
