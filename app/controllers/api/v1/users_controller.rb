class Api::V1::UsersController < Api::V1::BaseController
  before_action :set_user, only: [:show, :update, :destroy]

  # GET /api/v1/users
  def index
    @users = User.includes(:events).all
    render json: UserSerializer.new(@users, include: [:events]).serializable_hash
  end

  # GET /api/v1/users/:id
  def show
    render json: UserSerializer.new(@user, include: [:events]).serializable_hash
  end

  # POST /api/v1/users
  def create
    @user = User.new(user_params)
    
    if @user.save
      render json: UserSerializer.new(@user, include: [:events]).serializable_hash, status: :created
    else
      render json: { error: 'Failed to create user', details: @user.errors.full_messages }, 
             status: :unprocessable_content
    end
  end

  # PATCH/PUT /api/v1/users/:id
  def update
    if @user.update(user_params)
      render json: UserSerializer.new(@user, include: [:events]).serializable_hash
    else
      render json: { error: 'Failed to update user', details: @user.errors.full_messages }, 
             status: :unprocessable_content
    end
  end

  # DELETE /api/v1/users/:id
  def destroy
    @user.destroy
    head :no_content
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :phone, :password, :password_confirmation, event_ids: [])
  end
end
