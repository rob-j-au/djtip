class Api::V1::UsersController < Api::V1::BaseController
  before_action :set_user, only: [:show, :update, :destroy]

  # GET /api/v1/users
  def index
    @users = User.all
    render json: @users.as_json(include: :event)
  end

  # GET /api/v1/users/:id
  def show
    render json: @user.as_json(include: :event)
  end

  # POST /api/v1/users
  def create
    @user = User.new(user_params)
    
    if @user.save
      # Explicitly include event with its id to ensure it's in the response
      render json: @user.as_json(include: {event: {methods: :id}}), status: :created
    else
      render json: { error: 'Failed to create user', details: @user.errors.full_messages }, 
             status: :unprocessable_content
    end
  end

  # PATCH/PUT /api/v1/users/:id
  def update
    if @user.update(user_params)
      render json: @user.as_json(include: :event)
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
    params.require(:user).permit(:name, :email, :phone, :event_id)
  end
end
