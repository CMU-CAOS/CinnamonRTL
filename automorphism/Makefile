include ../simulation.mk

SRC = $(COMMON_SRC) $(TRANSPOSE_SRC) $(ARITHMETIC_SRC) \
	$(AUTOMORPHISM_SRC) $(AUTOMORPHISM_TEST_SRC)

all: automorphism_permutation automorphism

automorphism_permutation:
	$(call simulate,AutomorphismPermutationTest,$(SRC))

automorphism:
	$(call simulate,AutomorphismTest,$(SRC))
	$(call simulate,Automorphism4x4Test,$(SRC))
	$(call simulate,Automorphism8x8Test,$(SRC))
