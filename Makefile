EMACS ?= emacs

XDG_CACHE_HOME ?= $(HOME)/.cache
MELPAZOID_DIR  ?= $(XDG_CACHE_HOME)/melpazoid

ELC := ghostel.elc ghostel-debug.elc

.PHONY: all build check test test-all lint melpazoid byte-compile bench bench-quick clean

all: build test-all lint

build:
	./build.sh

check:
	zig build check

# Pattern rule: rebuild .elc whenever its .el source is newer.
# Make's timestamp tracking keeps the byte-compiled files in sync, so
# test targets never load stale .elc (Emacs prefers .elc over .el
# even when the source is newer, which silently masks edits).
%.elc: %.el
	$(EMACS) --batch -Q -L . --eval "(setq byte-compile-error-on-warn t)" -f batch-byte-compile $<

test: $(ELC)
	$(EMACS) --batch -Q -L . -l ert -l test/ghostel-test.el -f ghostel-test-run-elisp

test-all: build $(ELC)
	$(EMACS) --batch -Q -L . -l ert -l test/ghostel-test.el -f ghostel-test-run

byte-compile: $(ELC)

lint: byte-compile package-lint checkdoc

package-lint:
	$(EMACS) --batch -Q \
		--eval "(package-initialize)" \
		--eval "(require 'package-lint)" \
		-f package-lint-batch-and-exit \
		ghostel.el

checkdoc:
	$(EMACS) --batch -Q \
		--eval "(require 'checkdoc)" \
		--eval "(let ((sentence-end-double-space nil) \
		              (checkdoc-proper-noun-list nil) \
		              (checkdoc-verb-check-experimental-flag nil) \
		              (ok t)) \
		  (dolist (f '(\"ghostel.el\" \"ghostel-debug.el\")) \
		    (ignore-errors (kill-buffer \"*Warnings*\")) \
		    (let ((inhibit-message t)) \
		      (checkdoc-file f)) \
		    (when (get-buffer \"*Warnings*\") \
		      (setq ok nil) \
		      (with-current-buffer \"*Warnings*\" \
		        (message \"%s\" (buffer-string))))) \
		  (unless ok (kill-emacs 1)))"

melpazoid:
	@if [ ! -d "$(MELPAZOID_DIR)" ]; then \
		git clone https://github.com/riscy/melpazoid.git "$(MELPAZOID_DIR)"; \
	fi
	RECIPE='(ghostel :fetcher github :repo "dakra/ghostel")' \
		LOCAL_REPO=$(CURDIR) \
		make -C "$(MELPAZOID_DIR)"

bench:
	bash bench/run-bench.sh

bench-quick:
	bash bench/run-bench.sh --quick

clean:
	rm -f ghostel-module.dylib ghostel-module.so
	rm -f $(ELC)
	rm -rf zig-out .zig-cache
