.PHONY: *

SUBDIRS = common transpose montgomery_arithmetic arithmetic \
	ntt base_conv automorphism regfile top

MAKEFLAGS += --silent

default: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

clean:
	for target in $(SUBDIRS); do $(MAKE) -C $$target clean; done
