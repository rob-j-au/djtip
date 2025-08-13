RailsAdmin.config do |config|
  config.asset_source = :importmap

  ### Popular gems integration

  ## == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  ## == Authorization ==
  config.authorize_with do
    redirect_to main_app.root_path unless current_user&.admin?
  end

  ## == CancanCan ==
  # config.authorize_with :cancancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/railsadminteam/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  # config.show_gravatar = true

  # Application title
  config.main_app_name = ['djtip', 'Admin']

  # Model configuration for djtip application
  config.model 'Event' do
    list do
      field :title
      field :date
      field :location
      field :created_at
    end
    
    show do
      field :title
      field :description
      field :date
      field :location
      field :users
      field :performers
      field :tips
      field :created_at
      field :updated_at
    end
  end

  config.model 'User' do
    list do
      field :name
      field :email
      field :event
      field :created_at
    end
  end

  config.model 'Performer' do
    list do
      field :name
      field :bio
      field :event
      field :created_at
    end
  end

  config.model 'Tip' do
    list do
      field :amount
      field :message
      field :user
      field :event
      field :created_at
    end
  end

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end
end
