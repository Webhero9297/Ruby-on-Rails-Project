import os, re
import sys
import uuid
import pymongo





if len(sys.argv) < 4:
    print "You need to supply: source folder, destination folder and database. You can also specify a forth option if the script should not check if the listing exists pass in False."
    exit()
    
rootdir = sys.argv[1]
dest_dir = sys.argv[2]
database = sys.argv[3]

connection = pymongo.Connection('localhost', 27017)
db = connection[database]
col_listings = db['listings']
col_accounts = db['accounts']

for root, sub_folders, files in os.walk(rootdir):
    for filename in files:
        try:            
            if filename[0] == '.':
                continue
            

            fullpathtosrc = os.path.join(root, filename)

            match = re.match('^\w*', filename)
            if not match:
                continue
            listing_id = match.group(0)
            print {"listing_number": str.upper(listing_id)}

            parts = filename.split('-')

            if len(parts) != 3:
                continue

            listing = col_listings.find_one({"listing_number" : str.upper(listing_id)})
            if listing is None:
                print "Listing not found"
                continue

            account = col_accounts.find_one({"_id" : listing["account_id"]})
            account_number  = account["account_number"]
            account_country  = account["country_short"]


            newfilename = '%s-%s-%s'%(account_number, parts[1], parts[2])

            print newfilename

            if not os.path.exists(unicode.lower( '%s/%s'%(dest_dir, account_country) )):
                os.mkdir(unicode.lower( '%s/%s'%(dest_dir, account_country) ))

            fullpath = unicode.lower( '%s/%s/%s'%(dest_dir, account_country, account_number))
            if not os.path.exists(fullpath):
                os.mkdir(fullpath)
            
            print "Moving %s to %s/%s"%(fullpathtosrc, fullpath, newfilename)

            os.rename(fullpathtosrc, "%s/%s"%(fullpath, newfilename))

        except Exception, e:
            print e
exit()
