.PHONY: all a b c d

all: d

a b c:
	echo $@

d: a b c
	# Variables defined on the command line are automatically exported to they environment if the use legal shell syntax.
	echo $(OPTION)
	# Variable assignments from the command line are stored in the MAKEFLAGS variable along with command-line options.
	echo $(MAKEFLAGS)
