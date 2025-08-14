class NewAdmin::DashboardController < NewAdmin::BaseController
  def index
    set_page_title("Dashboard")
    
    # Gather statistics for dashboard
    @stats = {
      total_events: Event.count,
      total_users: User.count,
      total_performers: Performer.count,
      total_tips: Tip.count,
      total_tip_amount: Tip.sum(:amount) || 0,
      recent_events: Event.order(created_at: :desc).limit(5),
      recent_tips: Tip.includes(:user, :event).order(created_at: :desc).limit(10),
      top_tippers: User.where(:id.in => Tip.distinct(:user_id)).limit(5),
      admin_users: User.where(admin: true).count
    }
    
    # Chart data for the last 30 days
    @chart_data = {
      tips_by_day: tips_by_day_chart_data,
      events_by_month: events_by_month_chart_data
    }
  end
  
  private
  
  def tips_by_day_chart_data
    30.days.ago.to_date.upto(Date.current).map do |date|
      {
        date: date.strftime('%m/%d'),
        amount: Tip.where(created_at: date.beginning_of_day..date.end_of_day).sum(:amount).to_f
      }
    end
  end
  
  def events_by_month_chart_data
    6.months.ago.beginning_of_month.to_date.upto(Date.current).group_by(&:month).map do |month, dates|
      month_start = dates.first.beginning_of_month
      month_end = dates.last.end_of_month
      {
        month: month_start.strftime('%b %Y'),
        count: Event.where(created_at: month_start..month_end).count
      }
    end
  end
end
