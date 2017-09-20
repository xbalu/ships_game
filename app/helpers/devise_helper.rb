module DeviseHelper
  def devise_error_messages!
    if resource.errors.any?
      flash.now[:error] = resource.errors.full_messages.join('<br />').html_safe
    end
    return ''
  end
end
