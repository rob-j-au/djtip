class Api::V1::EventsController < Api::V1::BaseController
  before_action :set_event, only: [:show, :update, :destroy]

  # GET /api/v1/events
  def index
    @events = Event.all
    render json: @events.as_json(include: [:users, :performers])
  end

  # GET /api/v1/events/:id
  def show
    render json: @event.as_json(include: [:users, :performers])
  end

  # POST /api/v1/events
  def create
    @event = Event.new(event_params)
    
    if @event.save
      render json: @event.as_json(include: [:users, :performers]), status: :created
    else
      render json: { error: 'Failed to create event', details: @event.errors.full_messages }, 
             status: :unprocessable_content
    end
  end

  # PATCH/PUT /api/v1/events/:id
  def update
    if @event.update(event_params)
      render json: @event.as_json(include: [:users, :performers])
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
