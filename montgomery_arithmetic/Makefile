include ../simulation.mk

SRC = $(COMMON_SRC) $(MONTGOMERY_ARITHMETIC_SRC) $(MONTGOMERY_ARITHMETIC_TEST_SRC)

all: multiplier multiplier_adder montgomery_reducer montgomery_multiplier

multiplier:
	$(call simulate,MultiplierTest,$(SRC))

multiplier_adder:
	$(call simulate,MultiplierAdderTest,$(SRC))

montgomery_reducer:
	$(call simulate,MontgomeryReducerTest,$(SRC))

montgomery_multiplier:
	$(call simulate,MontgomeryMultiplierTest,$(SRC))
