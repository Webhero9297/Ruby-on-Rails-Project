# encoding: UTF-8
class Users::UsersController < ApplicationController
  filter_access_to :all
  layout 'dashboard'

  def show
    @user = current_user
    @account = current_user.account

    respond_to do |format|
      format.html
    end
  end


  def edit_primary_email
    @user = current_user
    @user_email = UserEmail.new

    respond_to do |format|
      format.html
      format.js
    end
  end

  ##
  # Saves the primary email that the user uses for login.
  # The email is also saved to the contact information email
  def save_primary_email
    @user = current_user
    @user_email = UserEmail.new
    @user_email.email = params[:user][:email]
    @user_email.current_email = params[:user][:current_email]

    respond_to do |format|
      if @user_email.valid? then
        @user.update_attribute(:email, params[:user][:email])
        @user.account.contact.set(:email, params[:user][:email])
        format.html {redirect_to( user_url)}
        format.js
      else
        format.html {render(action: :edit_primary_email)}
        format.js {render(action: :edit_primary_email)}
      end
    end
  end

  ##
  # Edit the secondary email on the user
  def edit_secondary_email
    @user = current_user
    @user_email = UserEmail.new

    respond_to do |format|
      format.html
      format.js
    end
  end

  ##
  # Saves the secondary email on the user.
  def save_secondary_email
    @user = current_user
    @user_email = UserEmail.new
    @user_email.secondary_email = params[:user][:secondary_email]
    @user_email.current_email = params[:user][:current_email]

    respond_to do |format|
      if @user_email.valid? then
        @user.update_attribute(:secondary_email, params[:user][:secondary_email])
        format.html {redirect_to( user_url)}
        format.js
      else
        format.html {render(action: :edit_secondary_email)}
        format.js {render(action: :edit_secondary_email)}
      end
    end
  end

  def delete_secondary_email
    current_user.secondary_email = nil
    current_user.save
    redirect_to(user_url)
  end

  ##
  # Edit the users full name
  def edit_full_name
    @user = current_user

    respond_to do |format|
      format.js
    end
  end

  ##
  # Saves the users full name
  def save_full_name
    @user = current_user
    @user.name = params[:user][:name]

    respond_to do |format|
      if @user.valid? then
        @user.save
        format.html {redirect_to(user_url)}
        format.js
      else
        format.js {render(action: :edit_full_name)}
      end
    end
  end


  def edit_password
    @user = current_user

    respond_to do |format|
      format.html
      format.js
    end
  end


  def connect_facebook
    @user = current_user

    respond_to do |format|
      format.html
      format.js
    end
  end


  def save_password
    @user = current_user

    respond_to do |format|
      if current_user.update_with_password(user_password_params) then
        sign_in(current_user, :bypass => true)
        format.html {redirect_to(user_url)}
        format.js
      else
        format.html {render(action: :edit_password)}
        format.js
      end
    end
  end

  ##
  # Used by agents and admins to change a user password
  def change_password_by_admin
    @user = User.has_permission(current_user).find(params[:id])

    respond_to do |format|
      format.html {render(layout: 'management')}
    end
  end

  ##
  # Used by agents and admins to change a user password
  def save_password_by_admin
    @user = User.has_permission(current_user).find(params[:id])

    respond_to do |format|
      if @user.update_attributes(admin_user_password_params)
        format.html {redirect_to(account_path(@user.account.id, anchor: 'account-users'))}
      else
        format.html {render(action: 'change_password_by_admin', layout: 'management')}
      end
    end
  end

  private

  def user_password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end

  def admin_user_password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
