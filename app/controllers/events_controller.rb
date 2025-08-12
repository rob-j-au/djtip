class EventsController < ApplicationController
  before_action :set_event, only: %i[ show edit update destroy ]

  # GET /events or /events.json
  def index
    @events = Event.all
  end

  # GET /events/1 or /events/1.json
  def show
  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit
  end

  # POST /events or /events.json
  def create
    @event = Event.new(event_params)
    combine_date_and_time(@event)

    respond_to do |format|
      if @event.save
        format.html { redirect_to @event, notice: "Event was successfully created." }
        format.json { render :show, status: :created, location: @event }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /events/1 or /events/1.json
  def update
    @event.assign_attributes(event_params)
    combine_date_and_time(@event)
    
    respond_to do |format|
      if @event.save
        format.html { redirect_to @event, notice: "Event was successfully updated." }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1 or /events/1.json
  def destroy
    @event.destroy!

    respond_to do |format|
      format.html { redirect_to events_path, status: :see_other, notice: "Event was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.require(:event).permit(:title, :description, :date, :time, :hour, :minute, :ampm, :location)
    end

    # Combine separate date and time fields into a single datetime
    def combine_date_and_time(event)
      if params[:event][:date].present?
        begin
          date_str = params[:event][:date]
          
          # Parse the date from the datepicker format (mm/dd/yyyy)
          date_part = Date.strptime(date_str, "%m/%d/%Y") rescue Date.parse(date_str)
          
          # Handle dropdown time fields (hour, minute, ampm)
          if params[:event][:hour].present? && params[:event][:minute].present? && params[:event][:ampm].present?
            hour = params[:event][:hour].to_i
            minute = params[:event][:minute].to_i
            ampm = params[:event][:ampm]
            
            # Convert 12-hour format to 24-hour format
            if ampm == 'AM' && hour == 12
              hour = 0
            elsif ampm == 'PM' && hour != 12
              hour += 12
            end
            
            # Combine date and time
            combined_datetime = DateTime.new(
              date_part.year,
              date_part.month,
              date_part.day,
              hour,
              minute,
              0
            )
            
            event.date = combined_datetime
          elsif params[:event][:time].present?
            # Fallback to single time field if present
            time_str = params[:event][:time]
            time_part = Time.parse(time_str)
            
            combined_datetime = DateTime.new(
              date_part.year,
              date_part.month,
              date_part.day,
              time_part.hour,
              time_part.min,
              time_part.sec
            )
            
            event.date = combined_datetime
          else
            # If only date is provided, set time to noon
            combined_datetime = DateTime.new(
              date_part.year,
              date_part.month,
              date_part.day,
              12,
              0,
              0
            )
            
            event.date = combined_datetime
          end
        rescue => e
          Rails.logger.error "Error combining date and time: #{e.message}"
          # If parsing fails, try to use the original date field
          begin
            event.date = DateTime.parse(params[:event][:date])
          rescue => parse_error
            Rails.logger.error "Error parsing date: #{parse_error.message}"
          end
        end
      end
    end
end
