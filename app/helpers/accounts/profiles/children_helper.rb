module Accounts::Profiles::ChildrenHelper
  
  def child_age(child)
    
    if child.age == 0
      return t('global.baby')
    end
    
    return child.age
  end
  
end
