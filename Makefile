# Makefile

BUILD_DIR       = $(shell pwd)
REPO_DIR        ?= $(BUILD_DIR)

ALL_RSC         := $(wildcard html/*.rsc html/*/*.rsc)
commitinfo.sh   := $(wildcard bin/commitinfo.sh)
GLOB_RSC        := $(wildcard html/AM-GlobalFunc.rsc)

SHELL := /bin/bash

include $(BUILD_DIR)/.config/config.mk

COMM_TAG := $(shell git rev-list --abbrev-commit --tags --max-count=1)
# `2>/dev/null` suppress errors and `|| true` suppress the error codes.
TAG := $(shell git describe --abbrev=0 --tags ${COMM_TAG} 2>/dev/null || true)
# here we strip the version prefix
TAG_VERS :=$(TAG:v%=%)
# get the latest commit hash in the short form
COMM_HASH := $(shell git rev-parse --short=8 HEAD 2>/dev/null) # Get short commit hash
#COMMIT := $(shell git rev-parse --short HEAD)
# get the latest commit date in the form of YYYYmmddHHMM ($(DTSTAMP_FMT))
COMM_DATE := $(shell git log -1 --format=%cd --date=format:$(DTSTAMP_FMT))
ifneq ($(COMM_HASH), $(COMM_TAG))
    TAG_VERS :=$(TAG_VERS)-next-$(COMM_HASH)-$(COMM_DATE)
endif
ifeq ($(TAG_VERS), )
    TAG_VERS :=$(COMM_HASH)-$(COMM_DATE)
endif
ifneq ($(shell git status --porcelain), )
    TAG_VERS :=$(TAG_VERS)-dirty
endif

.ONESHELL:

export BUILD_DIR REPO_DIR ALL_RSC GLOB_RSC

.DEFAULT_GOAL := run

.PHONY: run check commit notify checksums $(commitinfo.sh) test

run:
	@$(MAKE) check; rc=$$?; \
	if [ $$rc -eq 0 ]; then \
		echo "✅ [run] check $$rc, go to commitinfo.sh..."; \
		$(MAKE) $(commitinfo.sh); ci=$$?; \
		if [ $$ci -eq 0 ]; then \
			echo "✅ [run] commitinfo.sh exit $$ci. Go to checksums.sh..."; \
			$(MAKE) checksums; cs=$$?; \
			if [ $$cs -eq 0 ]; then \
				echo "✅ [run] checksums.sh exit $$cs. Do git add commit and push..."; \
				$(MAKE) commit; cm=$$?; \
				if [ $$cm -eq 0 ]; then \
					echo "✅ [run] commit exit $$cm. Exit Ok."; \
				else \
					$(MAKE) notify MSG="❌ [run] commit exit $$cm. Check it!"; \
				fi \
			else \
				$(MAKE) notify MSG="❌ [run] checksums.sh exit $$cs, check it!"; \
			fi \
		else \
			$(MAKE) notify MSG="❌ [run] commitinfo.sh exit $$ci, check it!"; \
		fi \
	else \
		echo "🧹 [run] check exit $$rc, repo is clean exit Ok."; \
	fi
	@echo "OK [run] done"

check:
	@bash bin/check_repo.sh

commit:
	cd $(BUILD_DIR)
	git add .
	git commit -m '$(COMM_INFO)'
	git push

notify:
	@bash bin/notify_telegram.sh "$(MSG)"

checksums: checksums.json

checksums.json: bin/checksums.sh $(ALL_RSC)
	bin/checksums.sh > html/tmp/$@

$(commitinfo.sh): $(GLOB_RSC)
	$(commitinfo.sh) $< > $<~
	mv $<~ $<

test:
	@bash -n bin/check_repo.sh
	@bash -n bin/notify_telegram.sh
	@bash -n bin/checksums.sh
	@bash -n bin/commitinfo.sh
	@echo "🧪 [test] syntax ok"

#clean:
#		echo "🧹"
#		git checkout HEAD -- .
