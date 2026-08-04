TREE_SITTER ?= tree-sitter
OUTER := tree-sitter-bg3-stats
VALUE := tree-sitter-bg3-stats-value
BUILD := build

.PHONY: generate build test test-grammar test-neovim clean

generate:
	cd $(OUTER) && $(TREE_SITTER) generate
	cd $(VALUE) && $(TREE_SITTER) generate

build: generate
	mkdir -p $(BUILD)/parser $(BUILD)/queries/bg3_stats $(BUILD)/queries/bg3_stats_value
	$(TREE_SITTER) build -o $(BUILD)/parser/bg3_stats.so $(OUTER)
	$(TREE_SITTER) build -o $(BUILD)/parser/bg3_stats_value.so $(VALUE)
	cp $(OUTER)/queries/*.scm $(BUILD)/queries/bg3_stats/
	cp $(VALUE)/queries/*.scm $(BUILD)/queries/bg3_stats_value/

test-grammar: generate
	$(TREE_SITTER) test -p $(OUTER)
	$(TREE_SITTER) test -p $(VALUE)

test-neovim: build
	nvim --clean --headless -u test/neovim.lua

test: test-grammar test-neovim

clean:
	rm -rf $(BUILD)
