class User < ApplicationRecord
  has_many :transactions, foreign_key: "sender_id"

  validates :external_id, uniqueness: { case_sensitive: false }

  before_create :set_default_allowance

  scope :active, -> { where(active: true).order(created_at: :desc) }

  def user_id
    return self.external_id
  end

  def transfer_points(recipient_user:, points:, message:, tags: [])
    if self.allowance >= points
      recipient_user.balance += points
      self.allowance -= points
      txn = Transaction.new(sender: self,
                            recipient: recipient_user,
                            amount: points,
                            message: message,
                            tags: tags)
      ActiveRecord::Base.transaction do
        self.save!
        recipient_user.save!
        txn.save!
      end
    else
      return false
    end
  rescue ActiveRecord::RecordInvalid => exception
    p exception.message
    return false
  end

  def self.award_or_deduct_points(users:, points:, message:, tags: [])
    system_user = User.find_by_username('system')

    ActiveRecord::Base.transaction do
      users.each do |u|
        u.balance += points
        u.save
        Transaction.create(sender:system_user,
                           recipient: u,
                           amount: points,
                           message: message,
                           transaction_type: Transaction.transaction_types[:admin],
                           tags: tags)
      end
    end
  end

  private

  def set_default_allowance
    self.allowance = ENV["DEFAULT_ALLOWANCE"]
    self.active = true
    self.display_name = self.username if self.display_name.blank?
  end

end
