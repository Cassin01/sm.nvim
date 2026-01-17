LUA_FILES := lua/sm/cmd.lua lua/sm/config.lua lua/sm/init.lua \
             lua/sm/links.lua lua/sm/memo.lua lua/sm/state.lua \
             lua/sm/tags.lua lua/sm/telescope.lua

all: $(LUA_FILES)

lua/sm/%.lua: fnl/sm/%.fnl | lua/sm
	fennel --compile $< > $@

lua/sm:
	mkdir -p $@

clean:
	rm -rf lua/

.PHONY: all clean
