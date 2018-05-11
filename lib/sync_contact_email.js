/*
Maps out and counts the number of matching and non matching contact email and user login email.
*/
function matching_email_report() {
    var matching = 0,
        non_matching = 0,
        errors = 0,
        user;

    db.accounts.find({terminated: false}).limit(2000).forEach(function(account) {
        user = db.users.findOne({_id : account.account_owner});

        try {
            if(user.email === account.contact.email) {
                matching = matching + 1;
            } else {
                non_matching = non_matching + 1;
            }
        }
        catch(e) {
            errors = errors + 1;
            print('Something wrong with the following account');
            print("AccountID: " + account._id);
            print("Account Owner: " + account.account_owner);
            print("-----------------------------------------------------");
        }
    });

    print("Matching emails: " + matching);
    print("None matching emails: " + non_matching);
    print("Errors: " + errors);
}

/*
Sets the account owners login email as contact email where they don't match and sets the contact email as secondary email on the user.
*/
function update_account_and_user_emails() {
    var user, doc_id;
    
    db.accounts.find({terminated: false}).limit(2000).forEach(function(account) {
        user = db.users.findOne({_id : account.account_owner});

        try {

            if(user.email !== account.contact.email) {
                // Creates a new ObjectId for the document since insert() does not return last id in 2.4.8 and below
                doc_id = new ObjectId;
                
                // Log the change before
                db.updated_contact_emails.insert({_id : doc_id, 'before' :
                    {
                        'name' : user.name,
                        'user_id' : user._id,
                        'contact_email' : account.contact.email === undefined ? null : account.contact.email,
                        'primary_email' : user.email,
                        'secondary_email' : user.secondary_email === undefined ? null : user.secondary_email,
                        'account_id' : account._id,
                        'created_at' : ISODate(new Date().toISOString())
                    },
                    'after' : {}
                });                

                // Sets the contact email as the scondary email
                db.users.update({_id : user._id}, {$set : {secondary_email : account.contact.email}});

                // Sets the login email (primary email) as the contect email
                db.accounts.update({_id : account._id}, {$set : {'contact.email' : user.email}});

                // Log the change after
                db.updated_contact_emails.update({_id : doc_id},
                    {
                        $set : {'after':{
                                            'name' : user.name,
                                            'user_id' : user._id,
                                            'contact_email' : account.contact.email === undefined ? null : account.contact.email,
                                            'primary_email' : user.email,
                                            'secondary_email' : user.secondary_email === undefined ? null : user.secondary_email,
                                            'account_id' : account._id,
                                            'created_at' : ISODate(new Date().toISOString())
                                        }
                                }   
                    });
                
            } 
            
        }
        catch(e) {
            print("Could not update account and user");
            print("AccountID: " + account._id);
            print("Account Owner: " + account.account_owner);
            print(e);
            print("-----------------------------------------------------");
        }
    });

}

matching_email_report();
update_account_and_user_emails();
matching_email_report();