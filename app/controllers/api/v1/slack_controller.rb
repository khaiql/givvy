class API::V1::SlackController < API::V1::APIController
  include APIHelper
  include ApplicationHelper

  def index
    # Verify caller source (slack token)
    # TODO

    # Sanitize inputs
    text = params[:text]
    action = text.split.first.to_s.downcase
    points = text[/\s(\d+)/].to_i
    recp_username = text.scan(/@?(\S+)\b/).flatten.first
    message = text.scan(/\d+\s(for)?(.+)/).flatten.last
    tags    = text.scan(/(#\S+)/).flatten
    response_text = nil

    # Find existing user
    user = User.find_by_username(params[:user_name])
    raise BailException, I18n.t('slack.user_not_found') if user == nil

    # Verify Slack user id vs external_id
    render :nothing, status: 401 if params[:user_id] != user.external_id

    # Handle action 'help'
    if action == "help" || text.blank?
      raise BailException, I18n.t('slack.help_message_with_balance', allowance: user.allowance, balance: user.balance)
    end

    # Handle action 'history', show last 20 transactions
    if action == "history"
      transactions = Transaction.for_user(user.id).limit(20)
      text = transactions.map do |t|
        if t.regular?
          I18n.t('slack.history.item_regular', date: format_time(time: t.created_at), sender: t.sender.username, recipient: t.recipient.username, amount: t.amount, message: t.message)
        elsif t.redemption?
          I18n.t('slack.history.item_redemption', date: format_time(time: t.created_at), amount: t.amount, reward: t.message)
        end
      end.join("\n")
      raise BailException, I18n.t('slack.history.last_10_wrapper', yield: text)
    end

    # Stupid input
    raise BailException, I18n.t('slack.invalid_syntax') if points <= 0
    raise BailException, I18n.t('slack.invalid_reason') if message.length < 3 || message.length > 256

    # Check allowance
    raise BailException, I18n.t('slack.insufficient_allowance') if points > user.allowance

    # Check recipient
    recipient = User.find_by_username(recp_username.downcase)
    raise BailException, I18n.t('slack.recipient_not_found') if recipient == nil
    raise BailException, I18n.t('slack.recipient_invalid') if recipient.id == user.id

    # Give bonus as a transaction
    success = user.transfer_points(recipient_user: recipient, points: points, message: message, tags: tags)
    raise BailException, I18n.t('slack.unable_to_transfer') if !success

    # Compose the public announcement message
    public_text = I18n.t('slack.gave_announce', sender:user.username, recipient:recipient.username, points: points)
    private_text = I18n.t('slack.gave_successful', recipient:recipient.username, points: points, allowance: user.allowance)
    attchs = [{
                title: message,
                color: '#00AADE',
                image_url: "#{request.protocol}#{request.host_with_port}/api/v1/slack_photo?s=#{user.username}&r=#{recipient.username}",
              }]

    # Announcement to in_channel or public
    if ENV['ANNOUNCE_MODE'] == 'in_channel'
      Thread.new {
        post_to_slack(channel: user.username, text: private_text)
      }
      render json: {
        response_type: 'in_channel',
        parse: 'full',
        text: public_text,
        attachments: attchs
      }
    else
      Thread.new {
        post_to_slack(channel: ENV['DEFAULT_CHANNEL'], text: public_text, attachments: attchs)
      }
      render json: {
        text: private_text
      }
    end

  rescue BailException => e
    render json: { text: e.message }
  rescue Exception => e
    render json: { text: I18n.t('slack.system_error', message: e.message + "\n\n" + params[:text]) }
  end


  def redeem
    # Sanitize inputs
    text = params[:text]
    rid = text.to_i
    raise BailException, I18n.t('slack.reward.invalid_reward_id') if text.present? && rid < 1

    # Find existing user
    user = User.find_by_username(params[:user_name])
    raise BailException, I18n.t('slack.user_not_found') if user == nil

    # Verify Slack user id vs external_id
    render :nothing, status: 401 if params[:user_id] != user.external_id

    # Print syntax
    if text.blank?
      msg = Reward.plaintext_list + "\n\n"
      msg += I18n.t('slack.reward.your_balance', balance:user.balance) + "\n\n"
      msg += I18n.t('slack.reward.syntax')
      raise BailException, msg
    end

    # Find that reward
    reward = Reward.available.find_by_id(rid)
    raise BailException, I18n.t('slack.reward.no_longer_available') if reward == nil

    # Insufficient balance
    raise BailException, I18n.t('slack.reward.insufficient_balance') if reward.cost > user.balance

    # Redemption
    success = reward.redeem_for(user:user)
    if success
      Thread.new {
        post_to_slack(channel:ENV['DEFAULT_CHANNEL'], text: I18n.t('slack.reward.redeem_announce', username: user.username, name:reward.name))
      }

      render json: {
        text: I18n.t('slack.reward.redeem_successfully', name:reward.name, cost:reward.cost, balance:user.balance),
        parse: "full"
      }
    else
      render json: {
        text: I18n.t('slack.reward.unable_to_redeem'),
      }
    end
  rescue BailException => e
    render json: { text: e.message }
  rescue Exception => e
    render json: { text: I18n.t('slack.system_error', message: e.message + "\n\n" + params[:text]) }
  end


  def photo
    s = params[:s].to_s
    r = params[:r].to_s
    render nothing: true, status: 404 if s.blank? || r.blank?

    # Get/generate photo
    blob = pair_photo(from_user: s.downcase, to_user: r.downcase)

    # Render image
    if blob == nil
      render nothing: true, status: 404 if !blob
    else
      send_data blob, type: 'image/png', disposition:'inline'
    end
  end

end
