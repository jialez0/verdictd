PROJDIR := $(shell readlink -f ..)
TOP_DIR := .
CUR_DIR := $(shell pwd)

# Root directory of the project (absolute path).
ROOTDIR=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
VERDICTD_VERSION := $(shell cat $(ROOTDIR)/VERSION)
VERDICTD_MAINTAINER := $(shell head -1 $(ROOTDIR)/MAINTAINERS)

######## APP Settings ########

Opa_Src_Files := opa_engine.go
App_Rust_Flags := --release

App_Rust_Path := $(TOP_DIR)/target/release
Opa_Lib_Path := $(CUR_DIR)/src/policy_engine/opa
Eaa_Name := eaa
Verdict_Name := verdict
Verdictd_Name := verdictd
Opa_Name := libopa.so

.PHONY: all clean distclean
all: $(Eaa_Name)

######## App Objects ########

opa:
	@cd "$(Opa_Lib_Path)" && go build -o $(Opa_Name) -buildmode=c-shared $(Opa_Src_Files)

$(Eaa_Name): opa
	RUSTFLAGS="-C link-args=-Wl,-rpath=/usr/local/lib/rats-tls:/usr/local/lib:$(Opa_Lib_Path),--enable-new-dtags" cargo build $(App_Rust_Flags)
	@echo "Cargo  =>  $@"

.PHONY: install uninstall clean

PREFIX := /usr/local
BINDIR := $(PREFIX)/bin
LIBDIR := $(PREFIX)/lib

install: $(Eaa_Name)
	@install -D -m0755 "$(App_Rust_Path)/$(Verdict_Name)" "$(BINDIR)"
	@install -D -m0755 "$(App_Rust_Path)/$(Verdictd_Name)" "$(BINDIR)"
	@install -D -m0755 "$(Opa_Lib_Path)/$(Opa_Name)" "$(LIBDIR)"

uninstall:
	@rm -f "$(BINDIR)/$(Verdict_Name)"
	@rm -f "$(BINDIR)/$(Verdictd_Name)"
	@rm -f "$(LIBDIR)/$(Opa_Name)"

package:
	$(MAKE) -C dist package VERDICTD_VERSION="$(VERDICTD_VERSION)" VERDICTD_MAINTAINER="$(VERDICTD_MAINTAINER)"

clean:
	cargo clean && rm -f Cargo.lock
	@rm -rf $(Opa_Lib_Path)/libopa.*
	@rm -f dist/rpm/verdictd.spec dist/deb/debian/changelog

distclean:
	$(MAKE) clean
