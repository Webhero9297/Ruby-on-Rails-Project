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
  //var date = new Date();
  var date = new Date(2013,07,01);
  //var exchange_id = "520386e7e3bbfe7e3d003059";
  //var exchange_id = "5203870ce3bbfe7e3d003e07";
  //var exchange_id = "5203870fe3bbfe7e3d003f39";
  var criteria = {"agreements.end_date" : {$lt : date}, status: {$ne : 'agreed'}};
  printjson(criteria);
  db.exchange_agreements.find(criteria).forEach(function(ea) {
      if(ea.agreements !== undefined) {
        // Fix all terms
        ea.agreements.forEach(function(agreement){            
          print(agreement.listing_number);
          
          db.exchange_agreements.update({'_id': ea._id, 'agreements._id':agreement._id}, {$set: {'agreements.$.car_exchange.accepted_by_partner': true}});
          db.exchange_agreements.update({'_id': ea._id, 'agreements._id':agreement._id}, {$set: {'agreements.$.long_distance_calls.accepted_by_partner': true}});
          db.exchange_agreements.update({'_id': ea._id, 'agreements._id':agreement._id}, {$set: {'agreements.$.cleaning.accepted_by_partner': true}});
          db.exchange_agreements.update({'_id': ea._id, 'agreements._id':agreement._id}, {$set: {'agreements.$.key_exchange.accepted_by_partner': true}});
          db.exchange_agreements.update({'_id': ea._id, 'agreements._id':agreement._id}, {$set: {'agreements.$.pets.accepted_by_partner': true}});
          db.exchange_agreements.update({'_id': ea._id, 'agreements._id':agreement._id}, {$set: {'agreements.$.other.accepted_by_partner': true}});

        });
        
        // Create signed activity
        var account_1 = db.accounts.findOne({'_id':ea.parties[0]});
        var account_2 = db.accounts.findOne({'_id':ea.parties[1]});
        
        var activity1 = {"_id":ObjectId(), "activity": "exchange_agreement.signed", "performed_by": account_1.contact.name, "user_id": account_1.account_owner,"created_at": date }
        var activity2 = {"_id":ObjectId(), "activity": "exchange_agreement.signed", "performed_by": account_2.contact.name, "user_id": account_2.account_owner,"created_at": date }
        
        print(account_1.contact.name);
        print(account_2.contact.name);

        db.exchange_agreements.update({'_id': ea._id}, {$push: {'activities': activity1}});
        db.exchange_agreements.update({'_id': ea._id}, {$push: {'activities': activity2}});


        //Add the parties to the signed_by_array
        db.exchange_agreements.update({'_id': ea._id}, {$addToSet: {'signed_by': account_1._id}});
        db.exchange_agreements.update({'_id': ea._id}, {$addToSet: {'signed_by': account_2._id}});

        //Set correct status
        db.exchange_agreements.update({'_id': ea._id}, {$set: {'status': 'agreed'}});
      }
    counter  = counter + 1;
    print(counter);  
  });

}


accept_terms();


function accept_terms_single(){
  var counter = 0;
  var agreement_id = ObjectId("523ac88be3bbfe0bf3000001")
  var date = new Date();

  db.exchange_agreements.find({_id: agreement_id}).forEach(function(ea) {
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

      /*
      var account_1 = db.accounts.findOne({'_id':ea.parties[0]});
      var account_2 = db.accounts.findOne({'_id':ea.parties[1]});
      
      var activity1 = {"_id":ObjectId(), "activity": "exchange_agreement.signed", "performed_by": account_1.contact.name, "user_id": account_1.account_owner,"created_at": date }
      var activity2 = {"_id":ObjectId(), "activity": "exchange_agreement.signed", "performed_by": account_2.contact.name, "user_id": account_2.account_owner,"created_at": date }
      

      db.exchange_agreements.update({'_id': ea._id}, {$push: {'activities': activity1}});
      db.exchange_agreements.update({'_id': ea._id}, {$push: {'activities': activity2}});
      */

  counter  = counter + 1;
  print(counter);  
  });

}


function clean_references(){
  var counter = 0;
  
  db.exchange_references.find({}).forEach(function(er) {
    
    var c = db.accounts.find({_id:er.account_id_1}).count();

    if(c == 0){
      counter = counter + 1;
      db.exchange_references.remove({account_id_1:er.account_id_1});
    }
    
  });
  print(counter);  

}








function build_collection(){
  var counter = 0;
  var map = function(){
    emit({listing_number_1: this.listing_number_1, listing_number_2: this.listing_number_2, start_date: this.start_date}, {count: 1}); 
  }

  var reduce = function(key, values) {
    var count = 0;

    values.forEach(function(v) {
      count += v['count'];
    });

    return {count: count};
  }

  var foo = db.exchange_references.mapReduce(map, reduce, {out: "fobbarshow"});
}

//db.exchange_references.remove({_id:docs[i]._id});


function clean_references_dups(){
  var counter = 0;
  var koo = db.fobbarshow.find({"value.count":{$gt:2}}).forEach(function(ko){
    var criteria = {listing_number_1:ko._id.listing_number_1, listing_number_2:ko._id.listing_number_2}
    counter += 1;

    var cursor = db.exchange_references.find(criteria)
    print("----------------------");
    var docs = cursor.toArray();
    print(docs.length);
    var limit = docs.length - 1;
    print(limit);
    for (var i = 0; i < limit; i++) {
      print(docs[i]._id);
      
    }
    print("@@@@@@@@@@@@@@@@@@@@@@");
  });
  print(counter);
}


