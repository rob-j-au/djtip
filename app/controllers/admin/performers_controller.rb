class Admin::PerformersController < Admin::BaseController
  before_action :set_performer, only: [:show, :edit, :update, :destroy]
  
  def index
    set_page_title("Performers")
    
    @performers = Performer.all
    
    # Search functionality
    if params[:search].present?
      @performers = search_collection(@performers, [:name, :genre, :bio], params[:search])
    end
    
    # Filter by genre
    if params[:genre].present?
      @performers = @performers.where(genre: params[:genre])
    end
    
    # Filter by event
    if params[:event_id].present?
      @performers = @performers.where(event_id: params[:event_id])
    end
    
    @performers = @performers.order(name: 1)
    @genres = Performer.where(:genre.exists => true, :genre.ne => "").pluck(:genre).uniq.compact.sort
    @events = Event.order(title: 1)
  end
  
  def show
    set_page_title("Performer: #{@performer.name}")
  end
  
  def new
    set_page_title("New Performer")
    @performer = Performer.new
    @events = Event.order(title: 1)
  end
  
  def create
    @performer = Performer.new(performer_params)
    
    if @performer.save
      redirect_to admin_performer_path(@performer), notice: 'Performer was successfully created.'
    else
      set_page_title("New Performer")
      @events = Event.order(title: 1)
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    set_page_title("Edit Performer: #{@performer.name}")
    @events = Event.order(title: 1)
  end
  
  def update
    if @performer.update(performer_params)
      redirect_to admin_performer_path(@performer), notice: 'Performer was successfully updated.'
    else
      set_page_title("Edit Performer: #{@performer.name}")
      @events = Event.order(title: 1)
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @performer.destroy
    redirect_to admin_performers_path, notice: 'Performer was successfully deleted.'
  end
  
  private
  
  def set_performer
    @performer = Performer.find(params[:id])
  end
  
  def performer_params
    params.require(:performer).permit(:name, :email, :password, :password_confirmation, :bio, :genre, :contact, :event_id)
  end
end
