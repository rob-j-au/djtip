namespace :admin do
  desc "Create an admin user"
  task create: :environment do
    email = ENV['ADMIN_EMAIL'] || 'admin@example.com'
    password = ENV['ADMIN_PASSWORD'] || 'password123'
    name = ENV['ADMIN_NAME'] || 'Admin User'

    user = User.find_or_initialize_by(email: email)
    
    if user.persisted?
      puts "Admin user already exists: #{user.email}"
      unless user.admin?
        user.make_admin!
        puts "Made #{user.email} an admin"
      else
        puts "#{user.email} is already an admin"
      end
    else
      user.assign_attributes(
        name: name,
        password: password,
        password_confirmation: password,
        admin: true
      )
      
      if user.save
        puts "Created admin user: #{user.email}"
        puts "Password: #{password}"
        puts "You can now access /admin with these credentials"
      else
        puts "Failed to create admin user:"
        user.errors.full_messages.each { |msg| puts "  - #{msg}" }
      end
    end
  end

  desc "List all admin users"
  task list: :environment do
    admins = User.where(admin: true)
    
    if admins.any?
      puts "Admin users:"
      admins.each do |admin|
        puts "  - #{admin.name} (#{admin.email})"
      end
    else
      puts "No admin users found"
    end
  end
end
