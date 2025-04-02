include ../simulation.mk

SRC = $(COMMON_SRC) $(REGFILE_SRC) $(REGFILE_TEST_SRC)

all: regfile

regfile:
	$(call simulate,RegfileTest,$(SRC))
