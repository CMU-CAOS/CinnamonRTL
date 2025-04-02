SIM = vcs
VERILATOR_PROC = 20
VERILATOR_FLAGS = --binary -j $(VERILATOR_PROC) --Wno-WIDTH
VCS_FLAGS = -full64 -sverilog -nc +warn=all
XCELIUM_FLAGS = -64bit -sv -nowarn NODNTW
MODELSIM_FLAGS = -mfcu -quiet -suppress 2892 -suppress 7061 -suppress 13314 -suppress 2583

ifeq ($(DEBUG), 1)
VCS_FLAGS += -debug_access+all
XCELIUM_FLAGS += -debug -gui
endif

MAKEFLAGS += --silent

define simulate_verilator
	verilator $(VERILATOR_FLAGS) $(2) --top-module $(1)
	./obj_dir/V$(1)
endef

define simulate_vcs
	bash vcs $(VCS_FLAGS) $(2) -top $(1)
	./simv
endef

define simulate_xcelium
	xrun $(XCELIUM_FLAGS) $(2) -top $(1)
endef

define simulate_modelsim
	vlog $(MODELSIM_FLAGS) $(2)
	vsim $(1) -c -do "run -all"
endef

ifeq ($(SIM), verilator)
simulate = $(call simulate_verilator,$(1),$(2))
endif
ifeq ($(SIM), vcs)
simulate = $(call simulate_vcs,$(1),$(2))
endif
ifeq ($(SIM), xcelium)
simulate = $(call simulate_xcelium,$(1),$(2))
endif
ifeq ($(SIM), modelsim)
simulate = $(call simulate_modelsim,$(1),$(2))
endif

default: all

clean:
	rm -rf obj_dir
	rm -rf AN.DB csrc simv simv.daidir ucli.key DVEfiles inter.vpd xrun.history xrun.log xcelium.d .simvision waves.shm xrun.key work transcript

# Source file

# Common
COMMON_SRC_REL = test_util.sv math.sv rect_mem.sv util.sv #cw_mult.sv
COMMON_TEST_SRC_REL = rect_mem_test.sv
COMMON_SRC = $(addprefix ../common/, $(COMMON_SRC_REL))
COMMON_TEST_SRC = $(addprefix ../common/test/, $(COMMON_TEST_SRC_REL))

# Transpose
TRANSPOSE_SRC_REL = transpose_unit.sv transpose_full.sv transpose_network_permutation.sv transpose.sv transpose_alloc.sv
TRANSPOSE_TEST_SRC_REL = transpose_unit_test.sv transpose_full_test.sv transpose_test.sv transpose_alloc_test.sv
TRANSPOSE_SRC = $(addprefix ../transpose/, $(TRANSPOSE_SRC_REL))
TRANSPOSE_TEST_SRC = $(addprefix ../transpose/test/, $(TRANSPOSE_TEST_SRC_REL))

# Montgomery Arithmetic
MONTGOMERY_ARITHMETIC_SRC_REL = multiplier.sv multiplier_adder.sv montgomery_reducer.sv montgomery_multiplier.sv montgomery_wrapper.sv
MONTGOMERY_ARITHMETIC_TEST_SRC_REL = multiplier_test.sv multiplier_adder_test.sv montgomery_reducer_test.sv montgomery_multiplier_test.sv
MONTGOMERY_ARITHMETIC_SRC = $(addprefix ../montgomery_arithmetic/, $(MONTGOMERY_ARITHMETIC_SRC_REL))
MONTGOMERY_ARITHMETIC_TEST_SRC = $(addprefix ../montgomery_arithmetic/test/, $(MONTGOMERY_ARITHMETIC_TEST_SRC_REL))

# Arithmetic
ARITHMETIC_SRC_REL = arithmetic_modular.sv
ARITHMETIC_TEST_SRC_REL = arithmetic_modular_test.sv
ARITHMETIC_SRC = $(addprefix ../arithmetic/, $(ARITHMETIC_SRC_REL))
ARITHMETIC_TEST_SRC = $(addprefix ../arithmetic/test/, $(ARITHMETIC_TEST_SRC_REL))

# NTT
NTT_SRC_REL = ntt_unit.sv ntt_mem.sv ntt_four_stage.sv
NTT_TEST_SRC_REL = ntt_unit_test.sv ntt_four_stage_test.sv
NTT_SRC = $(addprefix ../ntt/, $(NTT_SRC_REL))
NTT_TEST_SRC = $(addprefix ../ntt/test/, $(NTT_TEST_SRC_REL))

# Base Conv
BASE_CONV_SRC_REL = change_rns_base.sv crb_mem.sv rns_resolve.sv
BASE_CONV_TEST_SRC_REL = change_rns_base_test.sv rns_resolve_test.sv
BASE_CONV_SRC = $(addprefix ../base_conv/, $(BASE_CONV_SRC_REL))
BASE_CONV_TEST_SRC = $(addprefix ../base_conv/test/, $(BASE_CONV_TEST_SRC_REL))

# Automorphism
AUTOMORPHISM_SRC_REL = automorphism.sv
AUTOMORPHISM_TEST_SRC_REL = automorphism_test.sv
AUTOMORPHISM_SRC = $(addprefix ../automorphism/, $(AUTOMORPHISM_SRC_REL))
AUTOMORPHISM_TEST_SRC = $(addprefix ../automorphism/test/, $(AUTOMORPHISM_TEST_SRC_REL))

# Regfile
REGFILE_SRC_REL = regfile.sv
REGFILE_TEST_SRC_REL = regfile_test.sv
REGFILE_SRC = $(addprefix ../regfile/, $(REGFILE_SRC_REL))
REGFILE_TEST_SRC = $(addprefix ../regfile/test/, $(REGFILE_TEST_SRC_REL))
