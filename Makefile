PAGES := $(patsubst %.txt,%.html,$(wildcard *.txt))
ALL := $(PAGES) feed.rss

all: $(ALL)

clean:; rm -rf $(ALL)

feed.rss: rss.pl $(wildcard 2019-*.txt)
	perl rss.pl >$@

%.html: %.txt mark.pl
	perl mark.pl $< >$@
