# frozen_string_literal: true

class VenuesController < ApplicationController
  before_action :set_venue, only: %i[show edit update destroy]

  def index
    @venues = Venue.all
  end

  def show; end

  def new
    @venue = Venue.new
    @default_location = get_user_location
  end

  def edit
    @default_location = if @venue.location.present?
                          { lat: @venue.latitude, lng: @venue.longitude }
                        else
                          get_user_location
                        end
  end

  def create
    @venue = Venue.new(venue_params)

    if @venue.save
      redirect_to @venue, notice: 'Venue was successfully created.'
    else
      @default_location = get_user_location
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @venue.update(venue_params)
      redirect_to @venue, notice: 'Venue was successfully updated.'
    else
      @default_location = if @venue.location.present?
                            { lat: @venue.latitude, lng: @venue.longitude }
                          else
                            get_user_location
                          end
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @venue.destroy
    redirect_to venues_url, notice: 'Venue was successfully destroyed.'
  end

  private

  def set_venue
    @venue = Venue.find(params[:id])
  end

  def venue_params
    params.require(:venue).permit(:name, :venue_type, :latitude, :longitude)
  end

  def get_user_location
    result = Geocoder.search(request.remote_ip).first
    if result && result.coordinates.present?
      { lat: result.coordinates[0], lng: result.coordinates[1] }
    else
      # Default to Sydney, Australia if GeoIP fails
      { lat: -33.8688, lng: 151.2093 }
    end
  end
end
