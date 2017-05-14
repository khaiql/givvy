class RewardsController < ApplicationController
  before_action :set_reward, only: [:show, :edit, :update, :destroy]

  # GET /rewards
  def index
    @rewards = Reward.all
  end

  # GET /rewards/1
  def show
  end

  # GET /rewards/new
  def new
    @reward = Reward.new
  end

  # GET /rewards/1/edit
  def edit
  end

  # POST /rewards
  def create
    @reward = Reward.new(reward_params)

    if @reward.save
      redirect_to @reward, notice: 'Reward was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /rewards/1
  def update
    if @reward.update(reward_params)
      redirect_to @reward, notice: 'Reward was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /rewards/1
  def destroy
    @reward.destroy
    redirect_to rewards_url, notice: 'Reward was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_reward
      @reward = Reward.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def reward_params
      params.require(:reward).permit(:name, :image, :cost, :stock_count, :visible)
    end
end
