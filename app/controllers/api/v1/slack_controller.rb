class API::V1::SlackController < API::V1::APIController
  include APIHelper
  include ApplicationHelper

  def index
    # Verify caller source (slack token)
    # TODO

    # Sanitize inputs
    cmd  = params[:command]
    text = params[:text]
    action = text.split.first.to_s.downcase
    points = text[/\s(\d+)/].to_i
    recp_username = text.scan(/@(\S+)\b/).flatten.first
    message = text.scan(/\d+\s(for)?(.+)/).flatten.last
    tags    = text.scan(/(#\S+)/).flatten
    response_text = nil

    # Find existing user
    user = User.active.find_by_external_id(params[:user_id])
    raise BailException, I18n.t('slack.user_not_found') if user == nil

    # Handle action 'help'
    if action == "help" || text.blank?
      raise BailException, I18n.t('slack.help_message_with_balance', allowance: user.allowance, balance: user.balance, command: cmd)
    end

    # Handle action 'history', show last 20 transactions
    if action == "history"
      transactions = Transaction.for_user(user.id).limit(20)
      text = transactions.map do |t|
        if t.regular?
          I18n.t('slack.history.item_regular', date: format_time(time: t.created_at), sender: t.sender.user_id, recipient: t.recipient.user_id, amount: t.amount, message: t.message)
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
    recipient = User.active.where('username = ? OR external_id = ?', recp_username.downcase, recp_username).first
    raise BailException, I18n.t('slack.recipient_not_found') if recipient == nil
    raise BailException, I18n.t('slack.recipient_invalid') if recipient.id == user.id

    # Give bonus as a transaction
    success = user.transfer_points(recipient_user: recipient, points: points, message: message, tags: tags)
    raise BailException, I18n.t('slack.unable_to_transfer') if !success

    # Compose the public announcement message
    public_text = I18n.t('slack.gave_announce', sender:user.user_id, recipient:recipient.user_id, points: points)
    private_text = I18n.t('slack.gave_successful', recipient:recipient.user_id, points: points, allowance: user.allowance)
    pair_key = slack_encrypt(plain: user.user_id+"||"+recipient.user_id)
    attchs = [{
                title: message,
                color: '#00AADE',
                image_url: "#{request.protocol}#{request.host_with_port}/api/v1/slack_photo?k=#{pair_key}",
              }]

    # Announcement to in_channel or public
    if ENV['ANNOUNCE_MODE'] == 'in_channel'
      Thread.new {
        post_to_slack(channel: '@'+user.user_id, text: private_text)
      }
      render json: {
        response_type: 'in_channel',
        link_names: true,
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
    p e.backtrace[0..10]
    render json: { text: I18n.t('slack.system_error', message: e.message + "\n" + e.backtrace[0] + "\n" + params[:text]) }
  end


  def redeem
    # Sanitize inputs
    text = params[:text]
    rid = text.to_i
    raise BailException, I18n.t('slack.reward.invalid_reward_id') if text.present? && rid < 1

    # Find existing user
    user = User.active.find_by_external_id(params[:user_id])
    raise BailException, I18n.t('slack.user_not_found') if user == nil

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
        post_to_slack(channel:ENV['DEFAULT_CHANNEL'], text: I18n.t('slack.reward.redeem_announce', username: user.user_id, name:reward.name))
      }

      render json: {
        text: I18n.t('slack.reward.redeem_successfully', name:reward.name, cost:reward.cost, balance:user.balance),
        link_names: true
      }
    else
      render json: {
        text: I18n.t('slack.reward.unable_to_redeem')
      }
    end
  rescue BailException => e
    render json: { text: e.message }
  rescue Exception => e
    p e.backtrace[0..10]
    render json: { text: I18n.t('slack.system_error', message: e.message + "\n" + e.backtrace[0] + "\n" + params[:text]) }
  end

  def photo
    k = params[:k].to_s
    raise BailException if k.blank?

    # Decrypt string
    plain = slack_decrypt(encoded_str:k)
    raise BailException if plain.blank?
    s = plain.split("||")[0]
    r = plain.split("||")[1]
    raise BailException if s.blank? || r.blank?

    # Get/generate photo
    blob = pair_photo(from_user: s, to_user: r)
    raise BailException if !blob

    # Render image
    send_data blob, type: 'image/png', disposition:'inline'
  rescue BailException
    redirect_to '/unknown.png'
  rescue Exception => e
    p e.backtrace[0..10]
    render json: { text: I18n.t('slack.system_error', message: e.message) }
  end

end
