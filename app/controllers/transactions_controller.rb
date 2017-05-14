class TransactionsController < ApplicationController

  # GET /transactions
  def index
    @transactions = Transaction.paginate(page: params[:page], per_page: 30)
  end

end
