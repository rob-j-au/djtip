class Api::V1::PerformersController < Api::V1::BaseController
  before_action :set_performer, only: [:show, :update, :destroy]

  # GET /api/v1/performers
  def index
    @performers = Performer.all
    render json: @performers.as_json(include: :event)
  end

  # GET /api/v1/performers/:id
  def show
    render json: @performer.as_json(include: :event)
  end

  # POST /api/v1/performers
  def create
    @performer = Performer.new(performer_params)
    
    if @performer.save
      # Explicitly include event with its id to ensure it's in the response
      render json: @performer.as_json(include: {event: {methods: :id}}), status: :created
    else
      render json: { error: 'Failed to create performer', details: @performer.errors.full_messages }, 
             status: :unprocessable_content
    end
  end

  # PATCH/PUT /api/v1/performers/:id
  def update
    if @performer.update(performer_params)
      render json: @performer.as_json(include: :event)
    else
      render json: { error: 'Failed to update performer', details: @performer.errors.full_messages }, 
             status: :unprocessable_content
    end
  end

  # DELETE /api/v1/performers/:id
  def destroy
    @performer.destroy
    head :no_content
  end

  private

  def set_performer
    @performer = Performer.find(params[:id])
  end

  def performer_params
    params.require(:performer).permit(:name, :bio, :genre, :contact, :event_id)
  end
end
