# encoding: UTF-8
class Users::InvitationsController < Devise::InvitationsController
  
  def update
    self.resource = resource_class.accept_invitation!(resource_params)

    if resource.errors.empty?
      set_flash_message :notice, :updated
      sign_in(resource_name, resource)
      respond_with resource, :location => after_accept_path_for(resource)
    else
      respond_with_navigational(resource){ render :edit }
    end
  end

private
  def resource_params
    params.require(:user).permit(:password, :password_confirmation, :terms_and_conditions, :invitation_token)
  end
  
end