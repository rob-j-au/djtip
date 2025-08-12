class HomeController < ApplicationController
  def index
    @recent_events = Event.order(created_at: :desc).limit(3)
    @total_events = Event.count
    @total_users = User.count
    @total_performers = Performer.count
  end
end
