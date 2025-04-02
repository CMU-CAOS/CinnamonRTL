include ../simulation.mk

SRC = $(COMMON_SRC) $(ARITHMETIC_SRC) $(ARITHMETIC_TEST_SRC)

all: arithmetic_modular

arithmetic_modular:
	$(call simulate,ModularAdder4Test,$(SRC))
	$(call simulate,ModularAdder8Test,$(SRC))
	$(call simulate,ModularSubtractor10Test,$(SRC))
	$(call simulate,ModularMultiplier16Test,$(SRC))
	$(call simulate,ModularMultiplier45Test,$(SRC))
	$(call simulate,MultiplierTest,$(SRC))
	$(call simulate,ModularBarrettReductionTest,$(SRC))
