from PIL import Image
import os, re
import sys
import uuid
import pymongo

def pad_photo(original_image, new_width=1024, new_height=768, color=(255, 255, 255)):
    image_copy = original_image.copy()
    new_image_size = new_width, new_height
    new_image = Image.new('RGBA', new_image_size, color)
    
    original_size = image_copy.size
    width = original_size[0]
    height = original_size[1]

    new_ratio = float(new_width)/float(new_height)
    ratio = float(width)/float(height)


    if new_ratio == 1.0:
        if ratio > 1.0:
            hpercent = (new_height/float(image_copy.size[1]))
            wsize = int((float(image_copy.size[1])*float(hpercent)))
            image_copy = original_image.resize((new_width, wsize), Image.ANTIALIAS)
        else:
            image_copy = resize_image(image_copy, new_width)
        
        original_size = image_copy.size
        width = original_size[0]
        height = original_size[1]

        # Generate image
        vertical_diff = (new_width - width) / 2
        horizontal_diff = (new_height - height) / 2
        box_diff = (vertical_diff, horizontal_diff)
        
        new_image.paste(image_copy, box_diff)
        return new_image


    if ratio > 1.0:
        image_copy = resize_image(image_copy, new_width)
        original_size = image_copy.size
        width = original_size[0]
        height = original_size[1]
        
        # Generate image        
        vertical_diff = (new_width - width) / 2
        horizontal_diff = (new_height - height) / 2
        box_diff = (vertical_diff, horizontal_diff)
        
        new_image.paste(image_copy, box_diff)
        return new_image


    # If the original image is bigger then make it smaller before padding
    if ratio < 1.0 and (width > new_width or height > new_height):
        image_copy.thumbnail(new_image_size, Image.ANTIALIAS)
        original_size = image_copy.size
        width = original_size[0]
        height = original_size[1]
        
        # Generate image
        vertical_diff = (new_width - width) / 2
        horizontal_diff = (new_height - height) / 2
        box_diff = (vertical_diff, horizontal_diff)
        
        new_image.paste(image_copy, box_diff)
        return new_image





def resize_image(original_image, new_width=640):
    """docstring for resize_image"""
    wpercent = (new_width/float(original_image.size[0]))
    hsize = int((float(original_image.size[1])*float(wpercent)))
    new_img = original_image.resize((new_width, hsize), Image.ANTIALIAS)
    return new_img



def fix_image(infile, outpath):
    """docstring for fix_image"""
    # TODO If do not contain - (dash) then UUID or a stamp
    name, ext = os.path.splitext(infile)
    name = os.path.basename(name)
    
    # Create stamp for main photo
    split1 = name.split('-')
    if len(split1) == 1:
        the_uuid = str(uuid.uuid4()).replace('-', '')
        name = '-mp'.join((split1[0], the_uuid[:10]))
    
    base_name = "%s/%s-%s%s" %(outpath, name, '%s',ext)
    base_name = str.lower(base_name)
    
    # Check so that image doesn't already exists
    # TODO maybe have an overwrite flag?
    if os.path.exists(base_name % '458-auto'):
        print "Image already exists"
        print base_name % '458-auto'
        return
    
    
    original_image = Image.open(infile)

    # 1. Resize image to 458 in width
    resized_image = resize_image(original_image, 458)
    resized_image.save(base_name % '458-auto')

    #Gallery big
    pad_photo(resized_image, 458, 333).save(base_name % '458')
    
    #Gallery thumb
    pad_photo(original_image, 60, 60).save(base_name % '60')
    
    #Listings thumb
    pad_photo(original_image, 230, 147).save(base_name % '230')
    
    #Backend thumb
    pad_photo(original_image, 170, 128).save(base_name % '170')



if len(sys.argv) < 4:
    print "You need to supply: source folder, destination folder and database. You can also specify a forth option if the script should not check if the listing exists pass in False."
    exit()
    
rootdir = sys.argv[1]
dest_dir = sys.argv[2]
database = sys.argv[3]
check_listing = True
if len(sys.argv) > 4 and sys.argv[4] == 'False':
    check_listing = False

connection = pymongo.Connection('localhost', 27017)
db = connection[database]
col = db['listings']

for root, sub_folders, files in os.walk(rootdir):
    for filename in files:
        try:            
            if filename[0] == '.':
                continue
            
            country = filename[0:2]
            if not os.path.exists(str.lower( '%s/%s'%(dest_dir, country) )):
                os.mkdir(str.lower( '%s/%s'%(dest_dir, country) ))
            match = re.match('^\w*', filename)
            if not match:
                continue
            listing_id = match.group(0)
            print {"listing_number": str.upper(listing_id)}
            if check_listing:
                listing = col.find_one({"listing_number" : str.upper(listing_id)})
                if listing is None:
                    print "Listing not found"
                    continue

            if not os.path.exists(str.lower( '%s/%s/%s'%(dest_dir, country, listing_id) )):
                os.mkdir(str.lower( '%s/%s/%s'%(dest_dir, country, listing_id) ))
            print "Fixing image: %s"%filename
            fix_image('%s/%s' % (root, filename), '%s/%s/%s'%(dest_dir, country, listing_id))
        except Exception, e:
            print e
exit()
