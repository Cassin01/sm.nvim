# CLAUDE.md

## Build

```bash
make        # Compile Fennel to Lua
make test   # Run tests
make clean  # Remove generated Lua files
```

## Project Structure

- `fnl/sm/*.fnl` - Source files (Fennel)
- `lua/sm/*.lua` - Generated files (do not edit directly)
- `doc/sm.txt` - Vim help documentation

## Important

- **Source language**: Fennel (Lisp dialect compiling to Lua)
- **Generated files**: All `lua/` files are auto-generated from `fnl/`
- **Edit only**: `.fnl` files, never `.lua` files directly

## Git

- Use **English** for commit messages
- Use **English** for PR titles and descriptions
