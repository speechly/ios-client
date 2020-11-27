# Common vars
SWIFT      := swift
XCODE      := xcodebuild
BUILDPATH  := ./.build
DOCSPATH   := ./docs

# Deps vars
PACKAGE := Package.swift
DEPS    := $(BUILDPATH)/checkouts/

# Build vars
SOURCES          := $(shell find ./Sources -name '*.swift')
ARCHPATH         := $(BUILDPATH)/artifacts
BUILDDESTINATION ?= generic/platform=iOS
BUILDFLAGS       := -sdk iphoneos -destination '$(BUILDDESTINATION)'
BUILDSCHEME      := Speechly

# Test vars
TESTSOURCES     := $(shell find ./Tests -name '*.swift')
TESTDESTINATION ?= platform=iOS Simulator,name=iPhone 8
TESTFLAGS       := -destination '$(TESTDESTINATION)'
TESTSCHEME      := SpeechlyTests

# Build state vars
TESTBUILD    := $(ARCHPATH)/.test
DEBUGBUILD   := $(ARCHPATH)/.debug
RELEASEBUILD := $(ARCHPATH)/.release

# Common

.PHONY:
all: deps test release docs

.PHONY:
deps: $(DEPS)

.PHONY:
test: $(TESTBUILD)

.PHONY:
debug: $(DEBUGBUILD)

.PHONY:
release: $(RELEASEBUILD)

.PHONY:
clean:
	$(SWIFT) package clean
	@rm -rf $(BUILDPATH)
	@rm -rf $(DOCSPATH)

$(DOCSPATH): $(SOURCES)
	$(SWIFT) doc generate ./Sources/ --module-name Speechly --output $(DOCSPATH) --base-url ""

# Tests

$(TESTBUILD): $(SOURCES) $(TESTSOURCES) $(DEPS)
	$(XCODE) test $(TESTFLAGS) -scheme $(TESTSCHEME)
	@touch $@

# Builds

$(RELEASEBUILD): $(SOURCES) $(DEPS)
	$(XCODE) archive $(BUILDFLAGS) -archivePath "$(ARCHPATH)/release" -scheme $(BUILDSCHEME) -configuration Release
	@touch $@

$(DEBUGBUILD): $(SOURCES) $(DEPS)
	$(XCODE) archive $(BUILDFLAGS) -archivePath "$(ARCHPATH)/debug" -scheme $(BUILDSCHEME) -configuration Debug
	@touch $@

# Dependencies

$(DEPS): $(PACKAGE)
	$(SWIFT) package resolve
	@touch $@
