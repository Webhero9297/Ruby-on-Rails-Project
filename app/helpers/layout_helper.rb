# These helper methods can be called in your template to set variables to be used in the layout
# This module should be included in all views globally,
# to do so you may need to add this line to your ApplicationController
#   helper :layout
module LayoutHelper

  def yield_or_default(section, default = "")
    content_for?(section) ? content_for(section) : default
  end

  ##
  #
  def section_image(image_class)
    content_for(:section_image) { " #{image_class.to_s}" }
  end

  ##
  #
  def site_container_class(site_container_class)
    content_for(:site_container_class) { site_container_class.to_s}
  end

  ##
  #
  def body_id(body_id)
    content_for(:body_id) { body_id.to_s }
  end


  def page_title(page_title, has_page_title = true)
    content_for(:page_title) { page_title.to_s }
    @page_title = page_title
  end
  
  def has_page_title?
    @page_title
  end
  
  
  
  def page_description(page_description, has_page_description = true)
    content_for(:page_description) { page_description.to_s }
    @page_description = page_description
  end
  
  def has_page_description?
    @page_description
  end
  
  
  
  def page_keywords(page_keywords, has_page_keywords = true)
    content_for(:page_keywords) { page_keywords.to_s }
    @page_keywords = page_keywords
  end
  
  def has_page_keywords?
    @page_keywords
  end
  
  
  def body_classes(body_classes, has_body_classes = true)
    content_for(:body_classes) { body_classes.to_s }
    @body_classes = body_classes
  end
  
  def has_body_classes?
    @body_classes
  end
  
end