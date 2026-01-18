FNL_FILES := $(wildcard fnl/sm/*.fnl)
FNL_TEST_FILES := $(wildcard fnl/sm/*_test.fnl)
FNL_SRC_FILES := $(filter-out $(FNL_TEST_FILES),$(FNL_FILES))

LUA_FILES := $(patsubst fnl/sm/%.fnl,lua/sm/%.lua,$(FNL_SRC_FILES))
TEST_FILES := $(patsubst fnl/sm/%.fnl,lua/sm/%.lua,$(FNL_TEST_FILES))

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
