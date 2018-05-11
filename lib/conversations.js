function change_participants(){
  var counter = 0;
  db.conversations.find({participants: ObjectId("5201f8f8e3bbfe7b9109f7d3")}).forEach(function(conversation) {
      if(conversation.messages !== undefined) {

          conversation.messages.forEach(function(message){
              print(message.sent_by_account)
              if(message.sent_by_account == ObjectId("5201f8f8e3bbfe7b9109f7d3")){
                print("Sent by mark");
                //db.listings.update({'_id': listing._id, 'listing_images._id':image_obj._id}, {$set: {'listing_images.$.category': 'home'}});
              }
          });
      }

  counter  = counter + 1;
  print(counter);  
  });

}



function accept_terms(){
  var counter = 0;
  var account_id = ObjectId("52022714e3bbfe7b910c2094")
  var date = new Date();

  db.exchange_agreements.find({status: 'agreed'}).forEach(function(ea) {
      if(ea.agreements !== undefined) {
          ea.agreements.forEach(function(agreement){            
            
            db.exchange_agreements.update({'_id': ea._id, 'agreements._id':agreement._id}, {$set: {'agreements.$.car_exchange.accepted_by_partner': true}});
            db.exchange_agreements.update({'_id': ea._id, 'agreements._id':agreement._id}, {$set: {'agreements.$.long_distance_calls.accepted_by_partner': true}});
            db.exchange_agreements.update({'_id': ea._id, 'agreements._id':agreement._id}, {$set: {'agreements.$.cleaning.accepted_by_partner': true}});
            db.exchange_agreements.update({'_id': ea._id, 'agreements._id':agreement._id}, {$set: {'agreements.$.key_exchange.accepted_by_partner': true}});
            db.exchange_agreements.update({'_id': ea._id, 'agreements._id':agreement._id}, {$set: {'agreements.$.pets.accepted_by_partner': true}});
            db.exchange_agreements.update({'_id': ea._id, 'agreements._id':agreement._id}, {$set: {'agreements.$.other.accepted_by_partner': true}});

          });
      }

      var account_1 = db.accounts.findOne({'_id':ea.parties[0]});
      var account_2 = db.accounts.findOne({'_id':ea.parties[1]});
      
      var activity1 = {"_id":ObjectId(), "activity": "exchange_agreement.signed", "performed_by": account_1.contact.name, "user_id": account_1.account_owner,"created_at": date }
      var activity2 = {"_id":ObjectId(), "activity": "exchange_agreement.signed", "performed_by": account_2.contact.name, "user_id": account_2.account_owner,"created_at": date }
      

      db.exchange_agreements.update({'_id': ea._id}, {$push: {'activities': activity1}});
      db.exchange_agreements.update({'_id': ea._id}, {$push: {'activities': activity2}});
    

  counter  = counter + 1;
  print(counter);  
  });

}



function set_delivered(){
  var counter = 0;
  db.conversations.find({}).forEach(function(conversation) {
      if(conversation.messages !== undefined) {
          conversation.messages.forEach(function(message){
              if(message.statuses !== undefined) {
                message.statuses.forEach(function(status){
                  status.delivered = true;
                });
              }
          });
      db.conversations.save(conversation);
      }

  counter  = counter + 1;
  print(counter);  
  });

}

set_delivered();
