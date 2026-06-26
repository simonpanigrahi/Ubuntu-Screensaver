# Makefile for oled-screensaver
# Installs the OLED-safe screensaver as the `screensaver` command.
#
#   sudo make install        # -> /usr/local/bin/screensaver
#   sudo make uninstall
#
# Honors DESTDIR and PREFIX for packaging:
#   make install DESTDIR=/tmp/pkg PREFIX=/usr

PREFIX  ?= /usr/local
BINDIR  ?= $(PREFIX)/bin
INSTALL ?= install

.PHONY: all install uninstall

all:
	@echo "Nothing to build. Run 'make install' (optionally PREFIX=... DESTDIR=...)."

install:
	$(INSTALL) -D -m 0755 oled-safe.sh $(DESTDIR)$(BINDIR)/screensaver
	@echo "Installed: $(DESTDIR)$(BINDIR)/screensaver"

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/screensaver
	@echo "Removed:   $(DESTDIR)$(BINDIR)/screensaver"
