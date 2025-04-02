include ../simulation.mk

SRC = $(COMMON_SRC) $(TRANSPOSE_SRC) $(TRANSPOSE_TEST_SRC)

all: transpose_two transpose_high transpose_full transpose transpose_alloc

transpose_two:
	$(call simulate,TransposeTwoTest,$(SRC))
	$(call simulate,TransposeTwoRectTest,$(SRC))

transpose_high:
	$(call simulate,TransposeHighTest,$(SRC))
	$(call simulate,TransposeHighRectTest,$(SRC))

transpose_full:
	$(call simulate,TransposeFull8x8Test,$(SRC))
	$(call simulate,TransposeFull64x64Test,$(SRC))
	$(call simulate,TransposeFull256x256Test,$(SRC))
	$(call simulate,TransposeFull128x8Test,$(SRC))
	$(call simulate,TransposeFull8x128Test,$(SRC))

transpose:
	$(call simulate,Transpose8C4Test,$(SRC))
	$(call simulate,Transpose128C8Test,$(SRC))
	$(call simulate,Transpose256C4Test,$(SRC))

transpose_alloc:
	$(call simulate,TransposeAllocTest,$(SRC))
