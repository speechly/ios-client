# Common vars
SWIFT      := swift
XCODE	   := xcodebuild
BUILDPATH  := ./.build
DOCSPATH   := ./docs

# Build vars
SOURCES          := $(shell find ./Sources -name '*.swift')
ARCHPATH         := $(BUILDPATH)/artifacts
BUILDFLAGS       := -scheme speechly-ios-client -sdk iphoneos -destination 'generic/platform=iOS'

# Test vars
TESTSOURCES     := $(shell find ./Tests -name '*.swift')
TESTFLAGS       := -scheme speechly-ios-client -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 12'

# Build state vars
DEBUGBUILD   := $(ARCHPATH)/debug.xcarchive
RELEASEBUILD := $(ARCHPATH)/release.xcarchive

# Common

.PHONY:
all: deps test release docs

.PHONY:
deps: Package.swift
	$(SWIFT) package resolve

.PHONY:
test:
	$(XCODE) test $(TESTFLAGS)

.PHONY:
debug: $(DEBUGBUILD)

.PHONY:
release: $(RELEASEBUILD)

.PHONY:
clean:
	@$(SWIFT) package clean
	@rm -rf $(BUILDPATH)
	@rm -rf $(DOCSPATH)

$(DOCSPATH): $(SOURCES)
	$(SWIFT) doc generate ./Sources/ --module-name Speechly --output $(DOCSPATH) --base-url ""

$(RELEASEBUILD): $(SOURCES) Package.swift
	$(XCODE) archive $(BUILDFLAGS) -archivePath "$(ARCHPATH)/release" -configuration Release

$(DEBUGBUILD): $(SOURCES) Package.swift
	$(XCODE) archive $(BUILDFLAGS) -archivePath "$(ARCHPATH)/debug" -configuration Debug
