class TransactionsController < ApplicationController

  # GET /transactions
  def index
    @transactions = Transaction.page(params[:page]).per(30)
  end

end
