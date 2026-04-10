class Api::V1::PerformancesController < Api::V1::BaseController
  before_action :set_performance, only: [:show, :update, :destroy]

  def index
    @performances = Performance.includes(:performer, :event).all
    render json: PerformanceSerializer.new(@performances, include: [:performer, :event]).serializable_hash
  end

  def show
    render json: PerformanceSerializer.new(@performance, include: [:performer, :event]).serializable_hash
  end

  def create
    @performance = Performance.new(performance_params)
    
    if @performance.save
      render json: PerformanceSerializer.new(@performance, include: [:performer, :event]).serializable_hash, status: :created
    else
      render json: { error: 'Failed to create performance', details: @performance.errors.full_messages }, 
             status: :unprocessable_content
    end
  end

  def update
    if @performance.update(performance_params)
      render json: PerformanceSerializer.new(@performance, include: [:performer, :event]).serializable_hash
    else
      render json: { error: 'Failed to update performance', details: @performance.errors.full_messages }, 
             status: :unprocessable_content
    end
  end

  def destroy
    @performance.destroy
    head :no_content
  end

  private

  def set_performance
    @performance = Performance.find(params[:id])
  end

  def performance_params
    params.require(:performance).permit(:time, :performer_id, :event_id, :latitude, :longitude)
  end
end
