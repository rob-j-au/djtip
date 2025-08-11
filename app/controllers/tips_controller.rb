class TipsController < ApplicationController
  before_action :set_event
  before_action :set_tip, only: [:show, :edit, :update, :destroy]

  # GET /events/:event_id/tips
  def index
    @tips = @event.tips.includes(:user).recent
  end

  # GET /events/:event_id/tips/:id
  # GET /tips/1
  def show
  end

  # GET /events/:event_id/tips/new
  def new
    @tip = @event.tips.build
  end

  # GET /events/:event_id/tips/:id/edit
  def edit
  end

  # POST /events/:event_id/tips
  def create
    @tip = @event.tips.build(tip_params)

    respond_to do |format|
      if @tip.save
        format.html { redirect_to [@event, @tip], notice: 'Tip was successfully created.' }
        format.json { render :show, status: :created, location: [@event, @tip] }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @tip.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /tips/1
  def update
    respond_to do |format|
      if @tip.update(tip_params)
        format.html { redirect_to [@event, @tip], notice: 'Tip was successfully updated.' }
        format.json { render :show, status: :ok, location: [@event, @tip] }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @tip.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /tips/1
  def destroy
    @tip.destroy
    respond_to do |format|
      format.html { redirect_to event_tips_url(@event), notice: 'Tip was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_tip
    @tip = @event.tips.find(params[:id])
  rescue Mongoid::Errors::DocumentNotFound
    redirect_to event_tips_path(@event), alert: 'Tip not found.'
  end

  def set_event
    @event = Event.find(params[:event_id])
  rescue Mongoid::Errors::DocumentNotFound
    redirect_to events_path, alert: 'Event not found.'
  end

  # Only allow a list of trusted parameters through.
  def tip_params
    params.require(:tip).permit(:amount, :currency, :message, :user_id)
  end
end
