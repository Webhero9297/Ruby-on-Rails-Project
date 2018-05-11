/*
 One time run script to deactivate all Full year memberships for OC countries and set the price plan with the promotion code TRREOC10 as active and default.
*/
function deactivate_price_plans_for_oc() {
    var countries = db.countries.find({"price_plans.name" : "Full year membership", "price_plans.shared_id" : {$exists:true}, "price_plans.promotion_codes.code" : "TRREOC10"});

    countries.forEach(function(country) {
        country.price_plans.forEach(function(price_plan) {
            if(price_plan.kind === 'paid' && price_plan.shared_id === undefined && price_plan.active === true && price_plan.default === true) {
                
                price_plan.active = false;
                price_plan.default = false;
                price_plan.original = true;
                db.countries.save(country);
            }
        });
    });
}

deactivate_price_plans_for_oc();