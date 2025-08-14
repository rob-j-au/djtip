class Admin::TipsController < Admin::BaseController
  before_action :set_tip, only: [:show, :edit, :update, :destroy]
  
  def index
    set_page_title("Tips")
    
    @tips = Tip.includes(:user, :event).all
    
    # Search functionality
    if params[:search].present?
      user_ids = User.where(name: /#{Regexp.escape(params[:search])}/i).pluck(:id)
      event_ids = Event.where(title: /#{Regexp.escape(params[:search])}/i).pluck(:id)
      @tips = @tips.where('$or' => [
        { user_id: { '$in' => user_ids } },
        { event_id: { '$in' => event_ids } },
        { message: /#{Regexp.escape(params[:search])}/i }
      ])
    end
    
    # Filter by event
    if params[:event_id].present?
      @tips = @tips.where(event_id: params[:event_id])
    end
    
    # Filter by user
    if params[:user_id].present?
      @tips = @tips.where(user_id: params[:user_id])
    end
    
    # Filter by amount range
    if params[:min_amount].present?
      @tips = @tips.where(:amount.gte => params[:min_amount].to_f)
    end
    
    if params[:max_amount].present?
      @tips = @tips.where(:amount.lte => params[:max_amount].to_f)
    end
    
    # Filter by date range
    if params[:date_from].present?
      @tips = @tips.where(:created_at.gte => Date.parse(params[:date_from]).beginning_of_day)
    end
    
    if params[:date_to].present?
      @tips = @tips.where(:created_at.lte => Date.parse(params[:date_to]).end_of_day)
    end
    
    @tips = @tips.order(created_at: :desc)
    @events = Event.order(title: 1)
    @users = User.order(name: 1)
    @total_amount = @tips.sum(:amount)
  end
  
  def show
    set_page_title("Tip Details")
  end
  
  def edit
    set_page_title("Edit Tip")
    @events = Event.order(title: 1)
    @users = User.order(name: 1)
  end
  
  def update
    if @tip.update(tip_params)
      redirect_to admin_tip_path(@tip), notice: 'Tip was successfully updated.'
    else
      set_page_title("Edit Tip")
      @events = Event.order(title: 1)
      @users = User.order(name: 1)
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @tip.destroy
    redirect_to admin_tips_path, notice: 'Tip was successfully deleted.'
  end
  
  private
  
  def set_tip
    @tip = Tip.find(params[:id])
  end
  
  def tip_params
    params.require(:tip).permit(:amount, :currency, :message, :user_id, :event_id)
  end
end
