include ../simulation.mk

SRC = $(COMMON_SRC) $(ARITHMETIC_SRC) $(MONTGOMERY_ARITHMETIC_SRC) $(BASE_CONV_SRC) $(BASE_CONV_TEST_SRC)

all: change_rns_base rns_resolve

change_rns_base:
	# $(call simulate,ChangeRNSBaseMultiplyAccumulateTest,$(SRC))
	# $(call simulate,ChangeRNSBaseLaneTest,$(SRC))
	$(call simulate,ChangeRNSBaseTest,$(SRC))

rns_resolve:
	$(call simulate,RNSResolveBasicTest,$(SRC))
	$(call simulate,RNSResolveEx1Test,$(SRC))
	$(call simulate,RNSResolveEx2Test,$(SRC))
