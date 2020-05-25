.PHONY: a_b_c

targets += a_b_c

a_b_c:
	echo current directory: $(call subdir)
