function set_last_login_at(){
  var counter = 0;
  db.users.find({}).forEach(function(user) {
      if(user.account_id !== undefined) {
          var account = db.accounts.findOne({_id:user.account_id});
          if(account !== undefined) {
            if(account.last_login_at === undefined || account.last_login_at < user.last_sign_in_at){
              db.accounts.update({'_id': account._id}, {$set: {last_login_at: user.last_sign_in_at}});
            }
          }
      }
  });

  counter  = counter + 1;
  print(counter);  
}



function sorry(){
  var now = new Date();
  var criteria = {active: true, account_expires_at: {$gte: now}, account_terminated: false, "exchange_dates.earliest_date" : {$exists:1}};
  db.listings.find(criteria).forEach( function(x){
    var account = db.accounts.findOne({_id:x.account_id});
    db.sorry.insert({account_id:x.account_id, sent: false, country_code: account.country_short});
  });
}



function trim_translation(){
  var msgid = "webfeedback.visitor.suggestions_headline";

  db.translations.find({msgid:msgid}).forEach(function(translation){
    print(translation._id);
    translation._id = translation._id.replace(" ", "", "gi");
    if(translation.cloned_from){
      print(translation.cloned_from);
      translation.cloned_from = translation.cloned_from.replace(" ", "", "gi");
    }

    db.translations.save(translation);
    printjson(translation);
    
  });
}


function update_translation(){
  var msgid = "exchangetype.bed_&_breakfast";

  db.translations.find({msgid:msgid}).forEach(function(translation){
    
    translation._id = translation._id.replace("&", "and", "gi");
    translation.msgid = translation.msgid.replace("&", "and", "gi");
    if(translation.cloned_from){
      translation.cloned_from = translation.cloned_from.replace("&", "and", "gi");
    }
    
    printjson(translation);
    db.translations.insert(translation);
    printjson(db.getLastError());
    
    
    //quit();
  });
}

update_translation();

