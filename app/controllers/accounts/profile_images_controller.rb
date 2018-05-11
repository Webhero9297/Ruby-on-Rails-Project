# encoding: UTF-8
class Accounts::ProfileImagesController < ApplicationController
  filter_access_to :all
  layout "dashboard"

  def index
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @profile_image = ProfileImage.new

    @family_images = @profile.get_images_by_category('family')
    @lifestyle_images = @profile.get_images_by_category('lifestyle')

    respond_to do |format|
      format.html
    end
  end

  def create
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile

    @profile_image = @profile.profile_images.new(:category => params[:category])
    @profile_image.image = params[:file]

    respond_to do |format|
      if @profile_image.valid?
        @profile_image.save
        format.js { render( :json => {:html => render_to_string(partial: '/accounts/profile_images/image_card', object: @profile_image, as: 'image', locals: {account: @account})}, :status => 200)}
      else
        format.js { render( :json => {:error => 'validation failed', :image => @profile_image.errors.full_messages}, :status => 202 )}
      end
    end
  end

  def update
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @profile_image = @profile.profile_images.find(params[:id]).update_attributes!(profile_image_params)

    respond_to do |format|
      format.html { redirect_to(account_profiles_images_url(@account), {notice: t('alert.image_successfully_updated')}) }
    end
  end

  def destroy
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @profile.profile_images.destroy_all(conditions: { id: params[:id] })

    respond_to do |format|
      format.html { redirect_to(account_profiles_images_url(@account), {notice: t('alert.image_successfully_deleted')}) }
      format.js
    end
  end

  def set_public
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @profile_image = @profile.profile_images.find(params[:id])
    @profile_image.set_public()
    respond_to do |format|
      format.js {render( template: 'accounts/profile_images/reload_image.js.erb')}
    end
  end

  def set_private
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @profile_image = @profile.profile_images.find(params[:id])
    @profile_image.set_private()
    respond_to do |format|
      format.js {render( template: 'accounts/profile_images/reload_image.js.erb')}
    end
  end

  def rotate_left
    rotate :left
  end

  def rotate_right
    rotate :right
  end

  def set_order
    account = Account.has_permission(current_user).find(params[:account_id])
    profile = account.profile
    images_list = params[:images_list]
    profile.profile_images.set_order(images_list)
    render :nothing => true
  end

  def edit_caption
    @account = Account.find(params[:account_id])
    @profile = @account.profile
    @profile_image = @profile.profile_images.find(params[:id])
    respond_to do |format|
      format.html { redirect_to(account_profiles_images_url(@account), {notice: t('alert.image_successfully_updated')}) }
      format.js
    end
  end

  def update_caption
    @account = Account.find(params[:account_id])
    @profile = @account.profile
    @profile_image = @profile.profile_images.find(params[:id]).update_image(profile_image_params)
    respond_to do |format|
      format.html { redirect_to(account_profiles_images_url(@account), {notice: t('alert.image_successfully_updated')}) }
      format.js {render( template: 'accounts/profile_images/reload_image.js.erb')}
    end
  end

  def cancel_caption
    @account = Account.find(params[:account_id])
    @profile_image = @account.profile.profile_images.find(params[:id])
    respond_to do |format|
      format.js {render( template: 'accounts/profile_images/reload_image.js.erb')}
    end
  end

  def get_images
    @category = params[:category]
    @size = params[:size]
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @images = @profile.get_images_by_category([params[:category]])

    respond_to do |format|
      if @size == 'large'
        format.js { render(template: 'accounts/profile_images/get_images_large.js.erb') }
      end

      if @size == 'small'
        format.js { render(template: 'accounts/profile_images/get_images_small.js.erb') }
      end
    end
  end

  # FIXME: It should be extracted to an external module with the
  # common methods for anything related to photos and uploads for a
  # listing (merge with images_controller)
  def rotate direction
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile_image = @account.profile.profile_images.find(params[:id])
    @profile_image.rotate direction

    respond_to do |format|
      flash[:notice] = t('alert.image_successfully_updated')
      flash.keep(:notice)

      # pretty ugly, huh? For now it is the best way to just refresh
      # the page when the image is changed.
      format.js { render js: "window.location.reload();" }
      format.html { render html: redirect_to(listing_images_url(@listing)) }
    end
  end

  private

  def profile_image_params
    params.require(:profile_image).
      permit(:caption, :category, :publicly_visible, :main_photo)
  end
end
