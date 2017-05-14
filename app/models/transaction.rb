class Transaction < ApplicationRecord
  enum transaction_type: { regular: 0, redemption: 10, monthly_reset: 100, admin: 99 }

  scope :for_user, -> (user_id) { 
    where(sender_id: user_id)
    .or(Transaction.where(recipient_id: user_id))
    .includes(:sender, :recipient)
    .order(created_at: :desc)
  }

  def self.default_scope
    order(created_at: :desc)
  end

  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"
  belongs_to :reward, optional: true
  belongs_to :group, optional: true
end
