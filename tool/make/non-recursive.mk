targets :=

subdir = $(patsubst %/module.mk,%,$(word $(words $(MAKEFILE_LIST)),${MAKEFILE_LIST}))

.PHONY: all

include ./a/b/c/module.mk

all: $(targets)
	echo 'top level'
