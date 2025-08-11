class Api::V1::TipsController < Api::V1::BaseController
  before_action :set_event
  before_action :set_tip, only: [:show, :update, :destroy]

  # GET /api/v1/events/:event_id/tips
  def index
    @tips = @event.tips.includes(:user).recent
    render json: TipSerializer.new(@tips, include: [:event, :user]).serializable_hash
  end

  # GET /api/v1/tips/:id
  def show
    render json: TipSerializer.new(@tip, include: [:event, :user]).serializable_hash
  end

  # POST /api/v1/events/:event_id/tips
  def create
    @tip = @event.tips.build(tip_params)
    
    if @tip.save
      render json: TipSerializer.new(@tip, include: [:event, :user]).serializable_hash, status: :created
    else
      render json: { error: 'Failed to create tip', details: @tip.errors.full_messages }, 
             status: :unprocessable_content
    end
  end

  # PATCH/PUT /api/v1/tips/:id
  def update
    if @tip.update(tip_params)
      render json: TipSerializer.new(@tip, include: [:event, :user]).serializable_hash
    else
      render json: { error: 'Failed to update tip', details: @tip.errors.full_messages }, 
             status: :unprocessable_content
    end
  end

  # DELETE /api/v1/tips/:id
  def destroy
    @tip.destroy
    head :no_content
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  rescue Mongoid::Errors::DocumentNotFound
    render json: { error: 'Event not found' }, status: :not_found
    return false
  end

  def set_tip
    return false unless @event
    @tip = @event.tips.find(params[:id])
  rescue Mongoid::Errors::DocumentNotFound
    render json: { error: 'Tip not found' }, status: :not_found
    return false
  end

  def tip_params
    params.require(:tip).permit(:amount, :currency, :message, :user_id)
  end
end
