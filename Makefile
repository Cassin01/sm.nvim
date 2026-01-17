LUA_FILES := lua/sm/cmd.lua lua/sm/config.lua lua/sm/init.lua \
             lua/sm/links.lua lua/sm/memo.lua lua/sm/state.lua \
             lua/sm/tags.lua lua/sm/telescope.lua

TEST_FILES := lua/sm/config_test.lua lua/sm/links_test.lua \
              lua/sm/memo_test.lua lua/sm/state_test.lua lua/sm/tags_test.lua

all: $(LUA_FILES) $(TEST_FILES)

lua/sm/%.lua: fnl/sm/%.fnl | lua/sm
	fennel --compile $< > $@

lua/sm:
	mkdir -p $@

clean:
	rm -rf lua/

test: $(LUA_FILES) $(TEST_FILES)
	@for f in lua/sm/*_test.lua; do \
		echo "=== Running $$f ===" && \
		lua "$$f" || exit 1; \
	done
	@echo "=== All tests passed ==="

.PHONY: all clean test
