include ../simulation.mk

SRC = $(COMMON_SRC) $(TRANSPOSE_SRC) $(ARITHMETIC_SRC) $(MONTGOMERY_ARITHMETIC_SRC) $(NTT_SRC) $(NTT_TEST_SRC)

all: ntt_unit ntt_four_stage ntt_bubble

ntt_unit:
	$(call simulate,NTTUnitDIT4Test,$(SRC))
	$(call simulate,NTTUnitDIF4Test,$(SRC))

ntt_four_stage:
	$(call simulate,NTTFourStageTest,$(SRC))
	$(call simulate,NTTFourStage8x8Test,$(SRC))

ntt_bubble:
	$(call simulate,NTTBubbleTest,$(SRC))
