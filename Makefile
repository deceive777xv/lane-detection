#
# Usage:
# $ make (DEBUG=true) {compile,test,clean}-{docs,lane,rtl}
# 

.DEFAULT_GOAL: all
all: clean compile test

#
# Options; can be overridden by environment variables
#

LATEXMK_OUT		?= ./build/
LATEXMK_OPTS		?= -emulate-aux-dir -auxdir=./docs/ -xelatex -output-directory=$(LATEXMK_OUT)
export TEXINPUTS	:= $(CURDIR)/docs/assets/:$(CURDIR)/docs/research-paper/:$(CURDIR)/docs/plan-of-action/:$(CURDIR)/docs/timetable/:$(TEXINPUTS):
export BIBINPUTS	:= $(CURDIR)/docs/research-paper/:$(CURDIR)/docs/plan-of-action/:

LANE_DEPS		?= -lm
LANE_SRCS		?= $(wildcard ./src/lane_*.c)
#LANE_TESTS		?= $(wildcard ./test/lane_*_test.c)
LANE_TESTS		?= ./test/lane_image_ppm_test.c
LANE_OUT		?= ./build/lane

ifdef DEBUG
LANE_OPTS		?= -g3 -Wall -Werror -Wno-error=unknown-pragmas -DLANE_LOG_ENABLE
else
LANE_OPTS		?= -Wno-error=unknown-pragmas
endif

DOXYGEN_CONF		?= ./Doxyfile
VALGRIND_OPTS		?= --leak-check=full --show-leak-kinds=all --track-origins=yes --error-exitcode=1

DATA_EXEC		?= ./data/extract.sh
DATA_OUT		?= ./data/
DATA_TARGETS		?= $(wildcard $(DATA_OUT).ppm)$(wildcard $(DATA_OUT).jpg)

RTL_SRCS		?= $(wildcard ./rtl/hw_*.vhd)
RTL_OUT			?= ./build/
RTL_TARGET		?= hw_grayscale
RTL_SIMTIME		?= 100ns
RTL_WAVE		?= $(RTL_OUT)$(RTL_TARGET).vcd

ifdef DEBUG
RTL_GOALS		?= "-a ../rtl/$(RTL_TARGET).vhd" \
			   "-e $(RTL_TARGET)" \
			   "-r $(RTL_TARGET) --vcd=$(RTL_TARGET).vcd --stop-time=$(RTL_SIMTIME)"
else
# als we niet willen debuggen is analysis en elaboration genoeg
RTL_GOALS		?= "-a ../rtl/$(RTL_TARGET).vhd" \
			   "-e $(RTL_TARGET)"
endif

#
# Executable paths; can be overridden by env vars
#

LATEXMK_EXEC		?= /usr/bin/latexmk
GCC_EXEC		?= /usr/bin/gcc
VALGRIND_EXEC		?= /usr/bin/valgrind
GHDL_EXEC		?= /usr/bin/ghdl
DOXYGEN_EXEC		?= /usr/bin/doxygen
GTKWAVE_EXEC		?= /usr/bin/gtkwave
XDG_OPEN_EXEC		?= /usr/bin/xdg-open
RM_EXEC			?= /usr/bin/rm
MKDIR_EXEC		?= /usr/bin/mkdir
MAKE_EXEC		?= /usr/bin/make

#
# Compilation-related targets
#

make-out-dir:
	$(MKDIR_EXEC) -p $(LATEXMK_OUT)

compile-docs-project:
	$(LATEXMK_EXEC) $(LATEXMK_OPTS) docs/plan-of-action/project.tex

compile-docs-timetable:
	$(LATEXMK_EXEC) $(LATEXMK_OPTS) docs/timetable/timetable.tex

compile-docs-research:
	$(LATEXMK_EXEC) $(LATEXMK_OPTS) docs/research-paper/research.tex

compile-docs-code:
	$(DOXYGEN_EXEC) $(DOXYGEN_CONF)
	cd ./build/latex && $(MAKE_EXEC) all

compile-docs: make-out-dir compile-docs-project compile-docs-timetable compile-docs-research compile-docs-code

compile-lane: make-out-dir
	$(GCC_EXEC) $(LANE_OPTS) src/lane_*.c -o $(LANE_OUT) $(LANE_DEPS)

compile-rtl: make-out-dir
	# GHDL uses current directory as output, so cd into build dir first
	#(cd $(RTL_OUT) && eval "$(GHDL_EXEC) ${goal}");
	for goal in $(RTL_GOALS); do \
		(cd $(RTL_OUT); echo "$$goal"; eval "ghdl $$goal"); \
	done

compile: compile-docs compile-lane compile-rtl

#
# Cleaning-related targets
#

clean-docs-project:
	$(LATEXMK_EXEC) $(LATEXMK_OPTS) -CA docs/plan-of-action/project.tex

clean-docs-timetable:
	$(LATEXMK_EXEC) $(LATEXMK_OPTS) -CA docs/timetable/timetable.tex

clean-docs-research:
	$(LATEXMK_EXEC) $(LATEXMK_OPTS) -CA docs/research-paper/research.tex

clean-docs: clean-docs-project clean-docs-timetable clean-docs-research
	$(RM_EXEC) -rf $(LATEXMK_OUT)

clean-lane:
	$(RM_EXEC) -rf $(LANE_OUT)

clean-rtl:
	$(RM_EXEC) -rf $(RTL_OUT)

clean: clean-docs clean-lane clean-rtl

#
# Program execution target
# (todo: remove because lane_main.c is not used anymore, only test cases are used)
#

run-lane:
	$(LANE_OUT) data/0a0a0b1a-7c39d841.ppm data/0a0a0b1a-7c39d841.out.ppm

run: run-lane

#
# Inspect-** targets can be used on desktop to open
# the output of tasks in a GUI application.
#

inspect-rtl:
	$(GTKWAVE_EXEC) $(RTL_WAVE)

inspect-docs-project:
	$(XDG_OPEN_EXEC) docs/project.tex

inspect-docs-timetable:
	$(XDG_OPEN_EXEC) docs/timetable.tex

inspect-docs-research:
	$(XDG_OPEN_EXEC) docs/research.tex

#
# Test
#

test-lane-compile: compile-lane
	$(GCC_EXEC) $(LANE_OPTS) $(LANE_TESTS) $(filter-out ./src/lane_main.c, $(LANE_SRCS)) -I ./src/ -o build/lane_image_ppm_test $(LANE_DEPS)

test-lane-exec: test-lane-compile
	build/lane_image_ppm_test data/0a0a0b1a-7c39d841.ppm data/0a0a0b1a-7c39d841.out.ppm

test-lane-verify: test-lane-exec
	test/lane_image_ppm_test.sh

# Manual test, needs env vars ARG_SAMPLE and ARG_TEST
test-lane-man: make-out-dir
	$(GCC_EXEC) $(LANE_OPTS) "test/lane_$(ARG_TEST)_test.c" $(filter-out ./src/lane_main.c, $(LANE_SRCS)) -I ./src/ -o build/man_test $(LANE_DEPS)
ifdef VALGRIND
	$(VALGRIND_EXEC) $(VALGRIND_OPTS) --log-file="build/$(ARG_TEST).valgrind.log" build/man_test "data/$(ARG_SAMPLE).ppm" "data/$(ARG_SAMPLE).$(ARG_TEST).out.ppm"
else
	build/man_test "data/$(ARG_SAMPLE).ppm" "data/$(ARG_SAMPLE).$(ARG_TEST).out.ppm"
endif
	$(XDG_OPEN_EXEC) "data/$(ARG_SAMPLE).$(ARG_TEST).out.ppm"

test-lane: test-lane-verify

test: test-lane

