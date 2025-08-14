class NewAdmin::UsersController < NewAdmin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :toggle_admin]
  
  def index
    set_page_title("Users")
    
    @users = User.all
    
    # Search functionality
    if params[:search].present?
      @users = search_collection(@users, [:name, :email], params[:search])
    end
    
    # Filter by admin status
    case params[:filter]
    when 'admins'
      @users = @users.where(admin: true)
    when 'regular'
      @users = @users.where(admin: false)
    end
    
    @users = @users.order(:name)
  end
  
  def show
    set_page_title("User: #{@user.name}")
    
    @tips = @user.tips.includes(:event).order(created_at: :desc).limit(20)
    @total_tips = @user.tips.sum(:amount)
    @events_count = @user.tips.distinct(:event_id).count
  end
  
  def new
    set_page_title("New User")
    @user = User.new
  end
  
  def create
    @user = User.new(user_params)
    @user.password = SecureRandom.hex(8) if @user.password.blank?
    
    if @user.save
      redirect_to new_admin_user_path(@user), notice: 'User was successfully created.'
    else
      set_page_title("New User")
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    set_page_title("Edit User: #{@user.name}")
  end
  
  def update
    if @user.update(user_params)
      redirect_to new_admin_user_path(@user), notice: 'User was successfully updated.'
    else
      set_page_title("Edit User: #{@user.name}")
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @user == current_user
      redirect_to new_admin_users_path, alert: 'You cannot delete yourself.'
      return
    end
    
    @user.destroy
    redirect_to new_admin_users_path, notice: 'User was successfully deleted.'
  end
  
  def toggle_admin
    if @user == current_user
      redirect_to new_admin_user_path(@user), alert: 'You cannot change your own admin status.'
      return
    end
    
    @user.update!(admin: !@user.admin?)
    status = @user.admin? ? 'granted' : 'revoked'
    redirect_to new_admin_user_path(@user), notice: "Admin privileges #{status}."
  end
  
  private
  
  def set_user
    @user = User.find(params[:id])
  end
  
  def user_params
    params.require(:user).permit(:name, :email, :phone, :admin, :password, :password_confirmation)
  end
end
