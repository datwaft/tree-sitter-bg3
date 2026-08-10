TREE_SITTER ?= tree-sitter
PLENARY_PATH ?= $(HOME)/.local/share/nvim/lazy/plenary.nvim
OUTER := tree-sitter-bg3-stats
VALUE := tree-sitter-bg3-stats-value
THOTH := tree-sitter-bg3-thoth
OSIRIS := tree-sitter-bg3-osiris
BUILD := build

.PHONY: generate build test test-grammar test-neovim clean

generate:
	cd $(OUTER) && $(TREE_SITTER) generate
	cd $(VALUE) && $(TREE_SITTER) generate
	cd $(THOTH) && $(TREE_SITTER) generate
	cd $(OSIRIS) && $(TREE_SITTER) generate

build: generate
	mkdir -p $(BUILD)/parser $(BUILD)/queries/bg3_stats $(BUILD)/queries/bg3_stats_value $(BUILD)/queries/bg3_thoth $(BUILD)/queries/bg3_osiris
	$(TREE_SITTER) build -o $(BUILD)/parser/bg3_stats.so $(OUTER)
	$(TREE_SITTER) build -o $(BUILD)/parser/bg3_stats_value.so $(VALUE)
	$(TREE_SITTER) build -o $(BUILD)/parser/bg3_thoth.so $(THOTH)
	$(TREE_SITTER) build -o $(BUILD)/parser/bg3_osiris.so $(OSIRIS)
	cp $(OUTER)/queries/*.scm $(BUILD)/queries/bg3_stats/
	cp $(VALUE)/queries/*.scm $(BUILD)/queries/bg3_stats_value/
	cp $(THOTH)/queries/*.scm $(BUILD)/queries/bg3_thoth/
	cp $(OSIRIS)/queries/*.scm $(BUILD)/queries/bg3_osiris/

test-grammar: generate
	$(TREE_SITTER) test -p $(OUTER)
	$(TREE_SITTER) test -p $(VALUE)
	$(TREE_SITTER) test -p $(THOTH)
	$(TREE_SITTER) test -p $(OSIRIS)

test-neovim: build
	test -d $(PLENARY_PATH)
	BG3_TEST_ROOT=$(CURDIR) PLENARY_PATH=$(PLENARY_PATH) nvim --headless -u test/minimal_init.lua -c "PlenaryBustedDirectory test/integration { minimal_init = 'test/minimal_init.lua', sequential = true }"

test: test-grammar test-neovim

clean:
	rm -rf $(BUILD)
