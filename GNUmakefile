# This file is for building http://depq.rubyforge.org/.
#

RUBY = ruby

test:
	$(RUBY) -Ilib test/test-depq.rb

www:
	rm -rf www
	mkdir www
	rd2 -r rd/rd2html-lib.rb --html-title='Depq - Double-Ended Priority Queue' README > www/index.html
	rdoc --op www/rdoc -T frameless depq.rb

www-upload:
	scp -r www/. rubyforge.org:/var/www/gforge-projects/depq/
	echo http://depq.rubyforge.org/

.PHONY: test www www-upload
