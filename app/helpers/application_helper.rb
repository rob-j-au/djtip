module ApplicationHelper
  def user_avatar_image(user, size: :thumb, css_classes: "rounded-full object-cover")
    if user&.image_data? && user.image_url(size)
      image_tag user.image_url(size), alt: user.name, class: css_classes
    else
      # Fallback to default dancer image
      image_tag asset_path('female_dancer.png'), alt: user&.name || 'User', class: css_classes
    end
  end
end
