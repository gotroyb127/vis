-include config.mk

SRC = array.c buffer.c libutf.c main.c map.c register.c ring-buffer.c \
	sam.c text.c text-motions.c text-objects.c text-regex.c text-util.c \
	ui-curses.c view.c vis.c vis-lua.c vis-modes.c vis-motions.c \
	vis-operators.c vis-prompt.c vis-text-objects.c

# conditionally initialized, this is needed for standalone build
# with empty config.mk
PREFIX ?= /usr/local
SHAREPREFIX ?= ${PREFIX}/share
MANPREFIX ?= ${PREFIX}/man

VERSION = $(shell git describe 2>/dev/null || echo "0.2")

CONFIG_LUA ?= 1
CONFIG_ACL ?= 0
CONFIG_SELINUX ?= 0

CFLAGS_STD ?= -std=c99 -D_POSIX_C_SOURCE=200809L -D_XOPEN_SOURCE=700 -DNDEBUG
CFLAGS_STD += -DVERSION=\"${VERSION}\"
LDFLAGS_STD ?= -lc

CFLAGS_VIS = $(CFLAGS_AUTO) $(CFLAGS_TERMKEY) $(CFLAGS_CURSES) $(CFLAGS_ACL) \
	$(CFLAGS_SELINUX) $(CFLAGS_LUA) $(CFLAGS_STD)

CFLAGS_VIS += -DVIS_PATH=\"${SHAREPREFIX}/vis\"
CFLAGS_VIS += -DCONFIG_LUA=${CONFIG_LUA}
CFLAGS_VIS += -DCONFIG_SELINUX=${CONFIG_SELINUX}
CFLAGS_VIS += -DCONFIG_ACL=${CONFIG_ACL}
CFLAGS_VIS += ${CFLAGS_DEBUG}

LDFLAGS_VIS = $(LDFLAGS_AUTO) $(LDFLAGS_TERMKEY) $(LDFLAGS_CURSES) $(LDFLAGS_ACL) \
	$(LDFLAGS_SELINUX) $(LDFLAGS_LUA) $(LDFLAGS_STD)

CFLAGS_DEBUG_ENABLE = -UNDEBUG -O0 -g -ggdb -Wall -Wextra -pedantic \
	-Wno-missing-field-initializers -Wno-unused-parameter

STRIP?=strip

all: vis vis-menu

config.h:
	cp config.def.h config.h

config.mk:
	@touch $@

vis: config.h config.mk *.c *.h
	${CC} ${CFLAGS} ${CFLAGS_VIS} ${SRC} ${LDFLAGS} ${LDFLAGS_VIS} -o $@

vis-menu: vis-menu.c
	${CC} ${CFLAGS} ${CFLAGS_STD} ${CFLAGS_AUTO} ${CFLAGS_DEBUG} $< ${LDFLAGS} ${LDFLAGS_STD} ${LDFLAGS_AUTO} -o $@

debug: clean
	@$(MAKE) CFLAGS_DEBUG='${CFLAGS_DEBUG_ENABLE}'

profile: clean
	@$(MAKE) CFLAGS_DEBUG='${CFLAGS_DEBUG_ENABLE} -pg'

test-update:
	git submodule init
	git submodule update --remote --rebase

test:
	[ -e test/Makefile ] || $(MAKE) test-update
	@$(MAKE) -C test

clean:
	@echo cleaning
	@rm -f vis vis-menu vis-${VERSION}.tar.gz

dist: clean
	@echo creating dist tarball
	@git archive --prefix=vis-${VERSION}/ -o vis-${VERSION}.tar.gz HEAD

install: vis vis-menu
	@echo stripping executable
	@${STRIP} vis
	@echo installing executable file to ${DESTDIR}${PREFIX}/bin
	@mkdir -p ${DESTDIR}${PREFIX}/bin
	@cp -f vis ${DESTDIR}${PREFIX}/bin
	@chmod 755 ${DESTDIR}${PREFIX}/bin/vis
	@cp -f vis-menu ${DESTDIR}${PREFIX}/bin
	@chmod 755 ${DESTDIR}${PREFIX}/bin/vis-menu
	@cp -f vis-open ${DESTDIR}${PREFIX}/bin
	@chmod 755 ${DESTDIR}${PREFIX}/bin/vis-open
	@cp -f vis-clipboard ${DESTDIR}${PREFIX}/bin
	@chmod 755 ${DESTDIR}${PREFIX}/bin/vis-clipboard
	@test ${CONFIG_LUA} -eq 0 || { \
		echo installing support files to ${DESTDIR}${SHAREPREFIX}/vis; \
		mkdir -p ${DESTDIR}${SHAREPREFIX}/vis; \
		cp -r visrc.lua vis.lua lexers ${DESTDIR}${SHAREPREFIX}/vis; \
	}
	@echo installing manual page to ${DESTDIR}${MANPREFIX}/man1
	@mkdir -p ${DESTDIR}${MANPREFIX}/man1
	@sed -e "s/VERSION/${VERSION}/g" < vis.1 > ${DESTDIR}${MANPREFIX}/man1/vis.1
	@sed -e "s/VERSION/${VERSION}/g" -e "s/MONTH DAY, YEAR/$(date +'%B %m, %Y')/g" < vis-menu.1 > ${DESTDIR}${MANPREFIX}/man1/vis-menu.1
	@sed -e "s/VERSION/${VERSION}/g" -e "s/MONTH DAY, YEAR/$(date +'%B %m, %Y')/g" < vis-clipboard.1 > ${DESTDIR}${MANPREFIX}/man1/vis-clipboard.1
	@sed -e "s/VERSION/${VERSION}/g" -e "s/MONTH DAY, YEAR/$(date +'%B %m, %Y')/g" < vis-open.1 > ${DESTDIR}${MANPREFIX}/man1/vis-open.1
	@chmod 644 ${DESTDIR}${MANPREFIX}/man1/vis.1
	@chmod 644 ${DESTDIR}${MANPREFIX}/man1/vis-menu.1
	@chmod 644 ${DESTDIR}${MANPREFIX}/man1/vis-clipboard.1
	@chmod 644 ${DESTDIR}${MANPREFIX}/man1/vis-open.1

uninstall:
	@echo removing executable file from ${DESTDIR}${PREFIX}/bin
	@rm -f ${DESTDIR}${PREFIX}/bin/vis
	@rm -f ${DESTDIR}${PREFIX}/bin/vis-menu
	@rm -f ${DESTDIR}${PREFIX}/bin/vis-open
	@rm -f ${DESTDIR}${PREFIX}/bin/vis-clipboard
	@echo removing manual page from ${DESTDIR}${MANPREFIX}/man1
	@rm -f ${DESTDIR}${MANPREFIX}/man1/vis.1
	@echo removing support files from ${DESTDIR}${SHAREPREFIX}/vis
	@rm -rf ${DESTDIR}${SHAREPREFIX}/vis

.PHONY: all clean dist install uninstall debug profile test test-update
