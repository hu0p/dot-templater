# These targets don't produce files
.PHONY: clean
.PHONY: install
.PHONY: test

DESTDIR=/usr/bin
EXECFILE=dot-templater
TEST_RULES=test/rules
TEST_DOTFILES=test/dotfiles
TEST_DEST_DIR=test/dest
TEST_EXPECTED_DIR=test/expected

DIFF_FLAGS=-qNr
RUN_VALGRIND=yes
VALGRIND_FLAGS=--track-origins=yes --leak-check=full --show-leak-kinds=all --error-exitcode=1

CFLAGS=-std=c11 -O2 -Wall -Wextra -Wpedantic -Werror
SRCS:=$(wildcard *.c)
OBJS:=$(SRCS:.c=.o )

CLANG_FORMAT_OPTS="{\
		BasedOnStyle: llvm,\
		IndentWidth: 4,\
		AllowShortFunctionsOnASingleLine: None,\
		KeepEmptyLinesAtTheStartOfBlocks: false,\
		IndentCaseLabels: false,\
		BreakBeforeBraces: Linux}"

CLANG_TIDY_OPTS=\
	readability-braces-around-statements,misc-macro-parentheses

all: build

format:
	clang-format \
		-style=$(CLANG_FORMAT_OPTS)\
		-i $(SRCS)

	clang-tidy \
		-fix \
		-fix-errors \
		-header-filter=.* \
		--checks=$(CLANG_TIDY_OPTS) \
		*.c \
		-- -I .

%.o : %.c
	gcc $(CFLAGS) -c $< -o $@

build: $(OBJS)
	gcc $(OBJS) -o $(EXECFILE)

test:
	rm -rf $(TEST_DEST_DIR)
	mkdir $(TEST_DEST_DIR)
	if [ "$(RUN_VALGRIND)" == "yes" ]; then \
		valgrind $(VALGRIND_FLAGS) ./$(EXECFILE) $(TEST_RULES) $(TEST_DOTFILES) $(TEST_DEST_DIR); \
	else \
		./$(EXECFILE) $(TEST_RULES) $(TEST_DOTFILES) $(TEST_DEST_DIR); \
	fi
	diff $(DIFF_FLAGS) $(TEST_DEST_DIR) $(TEST_EXPECTED_DIR)
	if [ ! -x "$(TEST_DEST_DIR)/binary_file" ]; then \
		@echo "Expected binary_file to be executable."; \
		exit 1; \
	fi
	@echo "*** All tests successfully passed. ***"

clean:
	rm -f $(OBJS)
	find $(TEST_DEST_DIR) -mindepth 1 -delete

install:
	cp $(EXECFILE) $(DESTDIR)
