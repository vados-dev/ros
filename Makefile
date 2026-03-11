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

.PHONY: run check notify test
#checksums $(commitinfo.sh)

run: check
#	@echo "[run] start main flow"
	@echo "[run] done"

check:
	@bash bin/check_repo.sh

notify:
	@bash bin/notify_telegram.sh "manual notify from make"

checksums: checksums.json

checksums.json: bin/checksums.sh $(ALL_RSC)
		bin/checksums.sh > html/tmp/checksums.json

$(commitinfo.sh): $(GLOB_RSC)
		$(commitinfo.sh) $< > $<~
		mv $<~ $<

test:
	@bash -n bin/check_repo.sh
	@bash -n bin/notify_telegram.sh
	@bash -n bin/checksums.sh
	@bash -n bin/commitinfo.sh
	@echo "syntax ok"

#clean:
#		git checkout HEAD -- .
