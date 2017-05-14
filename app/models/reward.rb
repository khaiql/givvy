class Reward < ApplicationRecord
  has_many :transactions

  INFINITE_STOCK = 10000

  scope :available, -> { where(visible: true).where('stock_count > 0').order(id: :asc) }

  def self.default_scope
    order(id: :asc)
  end

  def self.plaintext_list
    Reward.where(visible: true).where('stock_count > 0').all.collect do |r|
      if r.stock_count == Reward::INFINITE_STOCK
        I18n.t('slack.reward.line_item', id:r.id, name:r.name, cost:r.cost)
      else
        I18n.t('slack.reward.line_item_stock_count', id:r.id, name:r.name, cost:r.cost, stock:r.stock_count)
      end
    end.join("\n")
  end

  def redeem_for(user:)
    if user.balance >= self.cost
      user.balance -= self.cost
      self.stock_count -= 1 unless self.stock_count == INFINITE_STOCK
      txn = Transaction.new(sender: user, recipient: user, message: self.name, amount: self.cost, reward: self, transaction_type: Transaction.transaction_types[:redemption])
      ActiveRecord::Base.transaction do
        self.save!
        user.save!
        txn.save!
      end
    else
      return false
    end
  rescue ActiveRecord::RecordInvalid => exception
    p exception.message
    return false
  end

end
