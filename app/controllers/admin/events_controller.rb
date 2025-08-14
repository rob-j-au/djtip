class Admin::EventsController < Admin::BaseController
  before_action :set_event, only: [:show, :edit, :update, :destroy, :toggle_status]
  
  def index
    set_page_title("Events")
    
    @events = Event.all
    
    # Search functionality
    if params[:search].present?
      @events = search_collection(@events, [:title, :location, :description], params[:search])
    end
    
    # Filter by date
    if params[:date_filter].present?
      case params[:date_filter]
      when 'upcoming'
        @events = @events.where(:date.gte => Time.current)
      when 'past'
        @events = @events.where(:date.lt => Time.current)
      when 'this_month'
        @events = @events.where(date: Time.current.beginning_of_month..Time.current.end_of_month)
      end
    end
    
    @events = @events.order(date: :desc)
  end
  
  def show
    set_page_title("Event: #{@event.title}")
    
    @users = @event.users.order(:name)
    @performers = @event.performers.order(:name)
    @tips = @event.tips.includes(:user).order(created_at: :desc).limit(20)
    @total_tips = @event.tips.sum(:amount)
  end
  
  def new
    set_page_title("New Event")
    @event = Event.new
  end
  
  def create
    @event = Event.new(event_params)
    
    if @event.save
      redirect_to new_admin_event_path(@event), notice: 'Event was successfully created.'
    else
      set_page_title("New Event")
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    set_page_title("Edit Event: #{@event.title}")
  end
  
  def update
    if @event.update(event_params)
      redirect_to new_admin_event_path(@event), notice: 'Event was successfully updated.'
    else
      set_page_title("Edit Event: #{@event.title}")
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @event.destroy
    redirect_to new_admin_events_path, notice: 'Event was successfully deleted.'
  end
  
  def toggle_status
    # This could be used for activating/deactivating events if you add a status field
    redirect_to new_admin_event_path(@event), notice: 'Event status updated.'
  end
  
  private
  
  def set_event
    @event = Event.find(params[:id])
  end
  
  def event_params
    params.require(:event).permit(:title, :description, :date, :location)
  end
end
