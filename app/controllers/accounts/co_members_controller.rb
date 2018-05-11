# encoding: UTF-8
class Accounts::CoMembersController < ApplicationController
  
  filter_access_to :all
  layout "dashboard"
  
  def index
    @account = Account.has_permission(current_user).find(params[:account_id])
    
    respond_to do |format|
      format.html
    end
  end
  
  def new
    @account = Account.has_permission(current_user).find(params[:account_id])
    @user = CoMember.new
    
    respond_to do |format|
      format.js
    end
  end

  def edit
    @account = Account.has_permission(current_user).find(params[:account_id])
    @user = User.find(params[:id])
    
    respond_to do |format|
      format.js
    end
  end

  def update
    @account = Account.has_permission(current_user).find(params[:account_id])
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.set_name_and_email(params[:user])
        flash[:notice] = "User details updated"
        format.js
      else
        format.js { render action: :edit }
      end
    end
  end
  
  def create
    @account = Account.has_permission(current_user).find(params[:account_id])
    @user = CoMember.new(co_member_params)
    
    respond_to do |format|
      if @user.valid? then
        
        @user = User.invite!(co_member_params)
        @account.users.push(@user)
        @user.save!(:validate => false)
        flash[:notice] = t('alert.family_member_invited')
        format.js {render(template: '/accounts/co_members/cancel.js.erb')}
      else
        format.js { render action: :new }
      end
    end
  end
  
  def destroy
    @account = Account.has_permission(current_user).find(params[:account_id])
    # TODO check for regresion problems when deleting an family member
    @family_member = User.find(params[:id])
    @family_member.destroy
    
    respond_to do |format|
      format.js {render(template: '/accounts/co_members/cancel.js.erb')}
    end
  end

  def cancel
    @account = Account.has_permission(current_user).find(params[:account_id])
    
    respond_to do |format|
      format.js
    end
  end

private

  def co_member_params
    params.require(:co_member).permit(:name, :email, :roles)
  end
end
