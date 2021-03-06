class UsersController < ApplicationController
  include SmartListing::Helper::ControllerExtensions
  helper  SmartListing::Helper

  before_action :set_user, only: [:show, :edit, :update, :destroy]

  # GET /users
  def index
    users_scope = User.order(created_at: :desc)
    users_scope = users_scope.where("username LIKE ?", "%#{params[:filter]}%") if params[:filter]
    @users = smart_listing_create :users, users_scope, partial: "users/listing"
  end

  # GET /users/1
  def show
    @transactions = Transaction.for_user(@user.id).limit(100)
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to @user, notice: 'User was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /users/1
  def update
    if @user.update(user_params)
      redirect_to @user, notice: 'User was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /users/1
  def destroy
    @user.destroy
    redirect_to users_url, notice: 'User was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:username, :display_name, :email, :allowance, :balance, :active)
    end
end
