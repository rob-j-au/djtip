module UsersHelper
  def user_avatar(user, size: 'w-10', ring_offset: 'ring-offset-2', css_classes: '')
    content_tag :div, class: "avatar#{' ' + css_classes unless css_classes.empty?}" do
      if user.image_data? && user.image_url(:thumb)
        content_tag :div, class: "#{size} rounded-full ring ring-primary ring-offset-base-100 #{ring_offset}" do
          image_tag user.image_url(:thumb), alt: user.name, class: "rounded-full object-cover"
        end
      else
        content_tag :div, class: "avatar placeholder" do
          content_tag :div, class: "bg-gradient-to-br from-primary to-secondary text-primary-content rounded-full #{size}" do
            content_tag :span, class: "text-xs font-bold" do
              user.name&.first&.upcase || 'U'
            end
          end
        end
      end
    end
  end

  def user_avatar_with_name(user, size: 'w-10', ring_offset: 'ring-offset-2', show_email: false)
    content_tag :div, class: "flex items-center gap-3" do
      concat user_avatar(user, size: size, ring_offset: ring_offset)
      concat(
        content_tag :div do
          concat content_tag(:div, user.name, class: "font-bold")
          if show_email
            concat content_tag(:div, user.email, class: "text-sm opacity-50")
          end
        end
      )
    end
  end
end
