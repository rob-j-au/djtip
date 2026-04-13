# frozen_string_literal: true

class PerformancesController < ApplicationController
  before_action :set_performance, only: %i[show edit update destroy]

  def index
    @performances = Performance.all.includes(:performer, :event)
  end

  def show; end

  def new
    @performance = Performance.new
    @performers = Performer.all
    @events = Event.all
    @default_location = get_user_location
  end

  def edit
    @performers = Performer.all
    @events = Event.all
    @default_location = if @performance.location.present?
                          { lat: @performance.latitude, lng: @performance.longitude }
                        else
                          get_user_location
                        end
  end

  def create
    @performance = Performance.new(performance_params)

    if @performance.save
      redirect_to @performance, notice: 'Performance was successfully created.'
    else
      @performers = Performer.all
      @events = Event.all
      @default_location = get_user_location
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @performance.update(performance_params)
      redirect_to @performance, notice: 'Performance was successfully updated.'
    else
      @performers = Performer.all
      @events = Event.all
      @default_location = if @performance.location.present?
                            { lat: @performance.latitude, lng: @performance.longitude }
                          else
                            get_user_location
                          end
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @performance.destroy
    redirect_to performances_url, notice: 'Performance was successfully destroyed.'
  end

  private

  def set_performance
    @performance = Performance.find(params[:id])
  end

  def performance_params
    params.require(:performance).permit(:time, :performer_id, :event_id, :latitude, :longitude)
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
