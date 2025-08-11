class Api::V1::EventsController < Api::V1::BaseController
  before_action :set_event, only: [:show, :update, :destroy]

  # GET /api/v1/events
  def index
    @events = Event.includes(:users, :performers, :tips).all
    render json: EventSerializer.new(@events, include: [:users, :performers, :tips]).serializable_hash
  end

  # GET /api/v1/events/:id
  def show
    render json: EventSerializer.new(@event, include: [:users, :performers, :tips]).serializable_hash
  end

  # POST /api/v1/events
  def create
    @event = Event.new(event_params)
    
    if @event.save
      render json: EventSerializer.new(@event, include: [:users, :performers, :tips]).serializable_hash, status: :created
    else
      render json: { error: 'Failed to create event', details: @event.errors.full_messages }, 
             status: :unprocessable_content
    end
  end

  # PATCH/PUT /api/v1/events/:id
  def update
    if @event.update(event_params)
      render json: EventSerializer.new(@event, include: [:users, :performers, :tips]).serializable_hash
    else
      render json: { error: 'Failed to update event', details: @event.errors.full_messages }, 
             status: :unprocessable_content
    end
  end

  # DELETE /api/v1/events/:id
  def destroy
    @event.destroy
    head :no_content
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:title, :description, :date, :location)
  end
end
