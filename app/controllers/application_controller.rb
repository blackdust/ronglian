class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  if defined? PlayAuth
    helper PlayAuth::SessionsHelper
    include PlayAuth::SessionsHelper
  end

  def default_render(*args)
    if @component_name.present? and not @component_data.nil?
      @component_name = @component_name.camelize
      return render "/react/page"
    else
      super
    end
  end

  def component(name, data)
    @component_name = name
    @component_data = data
  end
end
