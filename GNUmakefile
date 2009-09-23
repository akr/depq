# This file is for building http://depq.rubyforge.org/.
#

www:
	rm -rf www
	mkdir www
	rd2 README > www/index.html
	rdoc --op www/rdoc -T frameless depq.rb

www-upload:
	scp -r www/. akr@rubyforge.org:/var/www/gforge-projects/depq/
	echo http://depq.rubyforge.org/

.PHONY: www www-upload
