#export CFLAGS=-DUSE_EXE_NAME
export LDFLAGS=-static

PREFIX=/

.PHONY: all .FORCE

all: package

.PHONY: checkout

checkout: vim

vim:
	hg clone https://code.google.com/p/vim/ $@

.PHONY: build

build: .built

.built: vim/.update_stamp
	patch -N -p0 -i vim-use_local_data_dir.patch
	cd vim; ./configure \
		--prefix=$(PREFIX) \
		--bindir=$(PREFIX) \
		--datadir=$(PREFIX)/data \
		--mandir=$(PREFIX)/mandir \
		--with-features=normal \
		--enable-cscope \
		--enable-perlinterp \
		--enable-pythoninterp \
		--enable-rubyinterp
	make -C vim
	touch .built

vim/.update_stamp: .FORCE | vim
	@[ -e $@ -a -z "`find $(@D) -type d -o -name tags -o -name vim -o -path '*/auto/*' -o -path '*/objects/*' -prune -o -newer $@ -print -quit`" ] || touch $@

.PHONY: package 

package: vim.tgz

vim.tgz: .built
	[ ! -d out ] || rm -rf out
	mkdir -p out
	make -C vim/src installvimbin installrtbase DESTDIR=$(abspath out)
	[ ! -d out/mandir ] || rm -rf out/mandir
	find out -name doc -type d -exec rm -rf "{}" \; -quit
	tar -zcf $@ --xform 's/^out/vim/' out

.PHONY: clean

clean:
	[ ! -e vim ] || make -C vim distclean
	[ ! -e out ] || rm -rf out
	[ ! -e vim.tgz ] || rm -rf vim.tgz
	[ ! -e .built ] || rm -rf .built
