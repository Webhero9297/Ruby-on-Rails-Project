class ErrorsController < ApplicationController
  def not_found
    respond_to do |format|
      if is_mobile
        format.html { render template: "errors/mobile_not_found", layout: 'layouts/mobile', status: status }
      else
        format.html
      end
    end
  end

  def server_error
    respond_to do |format|
      if is_mobile
        format.html { render template: "errors/mobile_server_error", layout: 'layouts/mobile', status: status }
      else
        format.html
      end
    end
  end
end
