


var countries = {"Andorra":"AD", "United Arab Emirates":"AE", "Afghanistan":"AF", "Antigua and Barbuda":"AG", "Anguilla":"AI", "Albania":"AL", "Armenia":"AM", "Angola":"AO", "Netherlands Antilles":"AN", "Antarctica":"AQ", "Argentina":"AR", "American Samoa":"AS", "Austria":"AT", "Australia":"AU", "Aruba":"AW", "Aland Islands":"AX", "Azerbaidjan":"AZ", "Bosnia-Herzegovina":"BA", "Barbados":"BB", "Bangladesh":"BD", "Belgium":"BE", "Burkina Faso":"BF", "Bulgaria":"BG", "Bahrain":"BH", "Burundi":"BI", "Benin":"BJ", "Saint Barthelemy":"BL", "Bermuda":"BM", "Brunei Darussalam":"BN", "Bolivia":"BO", "Brazil":"BR", "Bahamas":"BS", "Bhutan":"BT", "Bouvet Island":"BV", "Botswana":"BW", "Belarus":"BY", "Belize":"BZ", "Canada":"CA", "Cocos (Keeling) Islands":"CC", "Democratic Rep. of Congo (Zaire)":"CD", "Central African Republic":"CF", "Congo":"CG", "Switzerland":"CH", "Ivory Coast":"CI", "Cook Islands":"CK", "Chile":"CL", "Cameroon":"CM", "China":"CN", "Colombia":"CO", "country.costa_rica":"CR", "Cuba":"CU", "Cape Verde":"CV", "Christmas Island":"CX", "Cyprus":"CY", "Czech Republic":"CZ", "Germany":"DE", "Djibouti":"DJ", "Denmark":"DK", "Dominica":"DM", "Dominican Republic":"DO", "Algeria":"DZ", "Ecuador":"EC", "Estonia":"EE", "Egypt":"EG", "Western Sahara":"EH", "Eritrea":"ER", "Spain":"ES", "Ethiopia":"ET", "Finland":"FI", "Fiji":"FJ", "Falkland Islands":"FK", "Liechtenstein":"LI", "Micronesia":"FM", "Faroe Islands":"FO", "Gabon":"GA", "Grenada":"GD", "Georgia":"GE", "French Guyana":"GF", "Guernsey":"GG", "Ghana":"GH", "Gibraltar":"GI", "Greenland":"GL", "Gambia":"GM", "Guinea":"GN", "Guadeloupe":"GP", "Equatorial Guinea":"GQ", "Greece":"GR", "South Georgia/Sandwich Islands":"GS", "Guatemala":"GT", "Guam":"GU", "Guinea Bissau":"GW", "Guyana":"GY", "Hong Kong":"HK", "Heard and McDonald Islands":"HM", "Honduras":"HN", "Croatia":"HR", "Haiti":"HT", "Hungary":"HU", "Indonesia":"ID", "Ireland":"IE", "Israel":"IL", "Isle of Man":"IM", "India":"IN", "British Indian Ocean Territory":"IO", "Iraq":"IQ", "Iran":"IR", "Iceland":"IS", "Italy":"IT", "Jersey":"JE", "Jamaica":"JM", "Jordan":"JO", "Japan":"JP", "Kenya":"KE", "Kyrgyz Republic":"KG", "Cambodia":"KH", "Kiribati":"KI", "Comoros":"KM", "Saint Kitts and Nevis":"KN", "North Korea":"KP", "South Korea":"KR", "Kuwait":"KW", "Cayman Islands":"KY", "Kazakhstan":"KZ", "Laos":"LA", "Lebanon":"LB", "Saint Lucia":"LC", "Sri Lanka":"LK", "Liberia":"LR", "Lesotho":"LS", "Lithuania":"LT", "Luxembourg":"LU", "Latvia":"LV", "Libya":"LY", "Morocco":"MA", "Monaco":"MC", "Moldova":"MD", "Republic of Montenegro":"ME", "Saint Martin":"MF", "Madagascar":"MG", "Marshall Islands":"MH", "Macedonia":"MK", "Mali":"ML", "Myanmar":"MM", "Mongolia":"MN", "Macau":"MO", "Northern Mariana Islands":"MP", "Martinique":"MQ", "Mauritania":"MR", "Montserrat":"MS", "Malta":"MT", "Mauritius":"MU", "Maldives":"MV", "Malawi":"MW", "Mexico":"MX", "Malaysia":"MY", "Mozambique":"MZ", "Namibia":"NA", "New Caledonia":"NC", "Niger":"NE", "Norfolk Island":"NF", "Nigeria":"NG", "Nicaragua":"NI", "Norway":"NO", "Nepal":"NP", "Nauru":"NR", "Niue":"NU", "New Zealand":"NZ", "Oman":"OM", "Panama":"PA", "Peru":"PE", "Netherlands":"NL", "Great Britain":"GB", "Polynesia":"PF", "Papua New Guinea":"PG", "Philippines":"PH", "Pakistan":"PK", "Poland":"PL", "Saint Pierre and Miquelon":"PM", "Pitcairn Islands":"PN", "Puerto Rico":"PR", "Palestinian Territory":"PS", "Portugal":"PT", "Palau":"PW", "Paraguay":"PY", "Qatar":"QA", "Reunion":"RE", "Romania":"RO", "Republic of Serbia":"RS", "Russia":"RU", "Rwanda":"RW", "Saudi Arabia":"SA", "Solomon Islands":"SB", "Seychelles":"SC", "Sudan":"SD", "Singapore":"SG", "Saint Helena":"SH", "Slovenia":"SI", "Svalbard and Jan Mayen Islands":"SJ", "Slovakia":"SK", "Sierra Leone":"SL", "San Marino":"SM", "Senegal":"SN", "Somalia":"SO", "Suriname":"SR", "Sao Tome and Principe":"ST", "El Salvador":"SV", "Syria":"SY", "Swaziland":"SZ", "Turks and Caicos Islands":"TC", "Chad":"TD", "French Southern Territories":"TF", "Togo":"TG", "Thailand":"TH", "Tadjikistan":"TJ", "Tokelau":"TK", "East Timor":"TL", "Turkmenistan":"TM", "Tunisia":"TN", "Tonga":"TO", "Turkey":"TR", "Trinidad and Tobago":"TT", "Tuvalu":"TV", "Taiwan":"TW", "Tanzania":"TZ", "Ukraine":"UA", "Uganda":"UG", "US Outlying Islands":"UM", "USA":"US", "Uruguay":"UY", "Uzbekistan":"UZ", "Vatican City State":"VA", "Saint Vincent/Grenadines":"VC", "Venezuela":"VE", "Virgin Islands (British)":"VG", "Virgin Islands (USA)":"VI", "Vietnam":"VN", "Vanuatu":"VU", "Wallis and Futuna":"WF", "Samoa":"WS", "Yemen":"YE", "Mayotte":"YT", "South Africa":"ZA", "Zambia":"ZM", "Zimbabwe":"ZW", "France":"FR", "Sweden":"SE"};




function set_wishlist(){

  var counter = 0;
  db.accounts.find({}).forEach(function(account) {
      if(account.profile !== undefined && account.profile.wish_list_destinations !== undefined) {

          account.profile.wish_list_destinations.forEach(function(wish){
          		//print(wish['destination']);
	       		var code = countries[wish['destination']];
	       		if(code === undefined){
	       			print(wish['destination'] + ' - ' + account['account_number']);

	       		}else{
	       			db.accounts.update({'_id': account._id, 'profile.wish_list_destinations._id':wish._id}, {$set: {'profile.wish_list_destinations.$.country_code': code}});	
	       		}
          });
      }
  counter  = counter + 1;
  print(counter);  
  });

}


function set_on_listing(){
  var counter = 0;
  db.accounts.find({'profile.wish_list_destinations': {$not: {$size : 0}}}).forEach(function(account) {
    if(account.profile !== undefined && account.profile.wish_list_destinations !== undefined) {

      var lists = [];
      account.profile.wish_list_destinations.forEach(function(wish){
        var foo = {'location': wish.location, 'ne_lat' : wish.ne_lat, 'ne_lng' : wish.ne_lng, 'sw_lat' : wish.sw_lat, 'sw_lng' : wish.sw_lng, 'country_code' : wish.country_code};
        lists.push(foo);

       });

      db.listings.find({account_id:account._id}).forEach(function(listing) {
         db.listings.update({'_id': listing._id}, {$set: {'account_wish_lists': lists}});

       });

    }
    counter  = counter + 1;
    print(counter);  
  });

}



function remove_restriction(){
  var counter = 0;
  var date = new Date();
  
  db.users.find({'roles': 'restricted' }).forEach(function(user) {
    db.accounts.find({'_id': user.account_id}).forEach(function(account) {

      account.subscriptions.forEach(function(sub){
        if(sub.active == true && sub.expires_at > date && sub.kind == 'paid'){
          db.users.update({'_id': user._id}, {$push: {'roles': 'member'}});          
          db.users.update({'_id': user._id}, {$pull: {'roles': 'restricted'}});          
          print("Remove restriction for member")
        }

        if(sub.active == true && sub.expires_at > date && sub.kind == 'free'){
          db.users.update({'_id': user._id}, {$push: {'roles': 'trial_member'}});          
          db.users.update({'_id': user._id}, {$pull: {'roles': 'restricted'}});          
          print("Remove restriction for trial")
        }
      });

    });

    counter += 1;
    print(counter);
  });

}


function update_accounts_listings(){
  var counter = 0;
    
  db.accounts_listings.find({'account_owner': {$exists:0} }).forEach(function(al) {
    db.accounts.find({'_id': al.account_id}).forEach(function(account) {
      print(account.account_number);
      db.accounts_listings.update({'_id': al._id}, {$set: {'account_owner': account.account_owner}});          
    });
    counter += 1;
    print(counter);
  });

}

update_accounts_listings();



