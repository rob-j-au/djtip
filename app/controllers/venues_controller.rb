# frozen_string_literal: true

class VenuesController < ApplicationController
  before_action :set_venue, only: %i[show edit update destroy]

  def index
    @venues = Venue.all
  end

  def show; end

  def new
    @venue = Venue.new
  end

  def edit; end

  def create
    @venue = Venue.new(venue_params)

    if @venue.save
      redirect_to @venue, notice: 'Venue was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @venue.update(venue_params)
      redirect_to @venue, notice: 'Venue was successfully updated.'
    else
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
    params.require(:venue).permit(:name, :venue_type)
  end
end
