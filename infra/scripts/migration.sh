rsync -azP -e 'ssh -p 4195 -i /home/intervac/.ssh/id_rsa' /var/webapps/intervac/attachments/ intervac@staging.intervac.com:/var/www/intervac/attachments
rsync -azP -e 'ssh -p 4195 -i /home/intervac/.ssh/id_rsa' /var/webapps/intervac/images/ intervac@staging.intervac.com:/var/www/intervac/images

#rsync -azP -e 'ssh -p 4195 -i /home/intervac/.ssh/id_rsa' /var/webapps/intervac/shared/bundle/ intervac@staging.intervac.com:/var/www/intervac/shared/bundle
rsync -azP -e 'ssh -p 4195 -i /home/intervac/.ssh/id_rsa' /var/webapps/intervac/shared/cache/ intervac@staging.intervac.com:/var/www/intervac/shared/cache
#rsync -azP -e 'ssh -p 4195 -i /home/intervac/.ssh/id_rsa' /var/webapps/intervac/shared/cached-copy/ intervac@staging.intervac.com:/var/www/intervac/shared/cached-copy
#rsync -azP -e 'ssh -p 4195 -i /home/intervac/.ssh/id_rsa' /var/webapps/intervac/shared/config/ intervac@staging.intervac.com:/var/www/intervac/shared/config
rsync -azP -e 'ssh -p 4195 -i /home/intervac/.ssh/id_rsa' /var/webapps/intervac/shared/exports/ intervac@staging.intervac.com:/var/www/intervac/shared/exports
rsync -azP -e 'ssh -p 4195 -i /home/intervac/.ssh/id_rsa' /var/webapps/intervac/shared/images/ intervac@staging.intervac.com:/var/www/intervac/shared/images
rsync -azP -e 'ssh -p 4195 -i /home/intervac/.ssh/id_rsa' /var/webapps/intervac/shared/log/ intervac@staging.intervac.com:/var/www/intervac/shared/log/old
#rsync -azP -e 'ssh -p 4195 -i /home/intervac/.ssh/id_rsa' /var/webapps/intervac/shared/pids/ intervac@staging.intervac.com:/var/www/intervac/shared/pids
#rsync -azP -e 'ssh -p 4195 -i /home/intervac/.ssh/id_rsa' /var/webapps/intervac/shared/system/ intervac@staging.intervac.com:/var/www/intervac/shared/system

cd /tmp
tar czvf hammerspace.tar.gz /tmp/hammerspace
scp -i /home/intervac/.ssh/id_rsa -P 4195 /tmp/hammerspace.tar.gz intervac@staging.intervac.com:/tmp

/usr/local/mongodb/bin/mongodump -d intervac_staging
mv dump/intervac_staging dump/intervac
sed -i 's/intervac_staging\./intervac./g' dump/intervac/*
tar czvf dump.tar.gz dump/
scp -i /home/intervac/.ssh/id_rsa -P 4195 /tmp/dump.tar.gz intervac@staging.intervac.com:/tmp
