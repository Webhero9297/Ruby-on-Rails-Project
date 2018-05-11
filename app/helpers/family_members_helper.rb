module FamilyMembersHelper
  
  def can_add_family_member(account_id)
    
    family_members = Account.find(account_id).users.count()
    
    if family_members < 2
      return true
    end
    
    return false
  end
  
end
