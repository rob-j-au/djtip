class NewAdmin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  
  layout 'new_admin/application'
  
  private
  
  def ensure_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied. Admin privileges required.'
    end
  end
  
  def set_page_title(title)
    @page_title = title
  end
  
  # Helper method for pagination
  def paginate_collection(collection, per_page: 20)
    page = params[:page] || 1
    # For Mongoid, we'll use simple offset/limit until Kaminari is configured
    offset = (page.to_i - 1) * per_page
    collection.skip(offset).limit(per_page)
  end
  
  # Helper method for search
  def search_collection(collection, search_fields, query)
    return collection if query.blank?
    
    conditions = search_fields.map do |field|
      { field => /#{Regexp.escape(query)}/i }
    end
    
    collection.or(conditions)
  end
end
