class User < ApplicationRecord
  has_many :transactions, foreign_key: "sender_id"

  validates :username, uniqueness: { case_sensitive: false }

  before_create :set_default_allowance

  def self.default_scope
    where(active: true)
  end

  def transfer_points(recipient_user:, points:, message:, tags: [])
    if self.allowance >= points
      recipient_user.balance += points
      self.allowance -= points
      txn = Transaction.new(sender: self, recipient: recipient_user, amount: points, message: message, tags: tags)
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

  private

  def set_default_allowance
    self.allowance = ENV["DEFAULT_ALLOWANCE"]
    self.active = true
    self.display_name = self.username if self.display_name.blank?
  end

end
