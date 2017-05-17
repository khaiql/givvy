class API::V1::AdminController < API::V1::APIController
  include APIHelper
  http_basic_authenticate_with :name => "admin", :password => ENV['ADMIN_PASSWORD']

  def give
    reason = params[:reason]
    points = params[:points].to_i
    tags = params[:tags_csv_no_hash].to_s.split(',')
    usernames = params[:usernames_csv].to_s.split(',')
    penalty = params[:penalty] == 'true'
    channel = params[:channel]
    return render json: {status: 'Invalid params'}, status: 400 if reason.blank? || points == 0 ||
                                                  usernames.count == 0 || tags.count == 0 ||
                                                  channel.blank? ||
                                                  (!penalty && points < 0) || (penalty && points > 0)

    # Find users
    users = User.where(username: usernames)
    return render json: {status: 'Usernames not found'}, status: 400 if users.count == 0

    # Transaction
    User.award_or_deduct_points(users: users, points: points, message: reason, tags: tags)

    # Make announcement
    attchs = users.collect do |u|
      {
        text: u.username,
        title: u.display_name,
        color: penalty ? 'danger' : 'good',
        thumb_url: u.avatar_url
      }
    end
    tags_joined = tags.map{|t| '#' + t }.join(' ')
    announce_msg = I18n.t(penalty ? 'admin_api.user_penalized' : 'admin_api.user_awarded', count: users.count, points: points, message: reason, tags: tags_joined)
    post_to_slack(channel: channel, text: announce_msg, attachments: attchs)
    render json: {
      status: 'Success'
    }
  end

end