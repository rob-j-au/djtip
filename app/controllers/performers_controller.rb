class PerformersController < ApplicationController
  before_action :set_performer, only: %i[ show edit update destroy ]

  # GET /performers or /performers.json
  def index
    @performers = Performer.all
  end

  # GET /performers/1 or /performers/1.json
  def show
  end

  # GET /performers/new
  def new
    @performer = Performer.new
    @events = Event.all
  end

  # GET /performers/1/edit
  def edit
    @events = Event.all
  end

  # POST /performers or /performers.json
  def create
    @performer = Performer.new(performer_params)

    respond_to do |format|
      if @performer.save
        format.html { redirect_to @performer, notice: "Performer was successfully created." }
        format.json { render :show, status: :created, location: @performer }
      else
        @events = Event.all
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @performer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /performers/1 or /performers/1.json
  def update
    respond_to do |format|
      if @performer.update(performer_params)
        format.html { redirect_to @performer, notice: "Performer was successfully updated." }
        format.json { render :show, status: :ok, location: @performer }
      else
        @events = Event.all
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @performer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /performers/1 or /performers/1.json
  def destroy
    @performer.destroy!

    respond_to do |format|
      format.html { redirect_to performers_path, status: :see_other, notice: "Performer was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_performer
      @performer = Performer.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def performer_params
      params.require(:performer).permit(:name, :bio, :genre, :contact, :event_id)
    end
end
