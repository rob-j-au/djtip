class Api::V1::VenuesController < Api::V1::BaseController
  before_action :set_venue, only: [:show, :update, :destroy]

  def index
    @venues = Venue.includes(:events).all
    render json: VenueSerializer.new(@venues, include: [:events]).serializable_hash
  end

  def show
    render json: VenueSerializer.new(@venue, include: [:events]).serializable_hash
  end

  def create
    @venue = Venue.new(venue_params)
    
    if @venue.save
      render json: VenueSerializer.new(@venue, include: [:events]).serializable_hash, status: :created
    else
      render json: { error: 'Failed to create venue', details: @venue.errors.full_messages }, 
             status: :unprocessable_content
    end
  end

  def update
    if @venue.update(venue_params)
      render json: VenueSerializer.new(@venue, include: [:events]).serializable_hash
    else
      render json: { error: 'Failed to update venue', details: @venue.errors.full_messages }, 
             status: :unprocessable_content
    end
  end

  def destroy
    @venue.destroy
    head :no_content
  end

  private

  def set_venue
    @venue = Venue.find(params[:id])
  end

  def venue_params
    params.require(:venue).permit(:name, :venue_type)
  end
end
