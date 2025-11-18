project_dir := justfile_directory()

# print available just recipes
[group('project-agnostic')]
default:
    @just --list --justfile {{justfile()}}

# evaluate and print all just variables
[group('project-agnostic')]
just-vars:
    @just --evaluate

# print system information such as OS and architecture
[group('project-agnostic')]
system-info:
    @echo "architecture: {{arch()}}"
    @echo "os: {{os()}}"
    @echo "os family: {{os_family()}}"

# build console Linux binary
[group('development')]
build-linux-console:
    (cd src && make -f Makefile.std clean install) || exit 1
    @echo "Run the game via 'sil' in the top-level project folder"

# build console macOS binary
[group('development')]
build-macos-console:
    (cd src && make -f Makefile.osx-console clean install) || exit 1
    @echo "Run the game via 'sil' in the top-level project folder"

# build native macOS app
[group('development')]
build-macos-app:
    (cd src && make -f Makefile.cocoa clean install) || exit 1
    @echo "Run the game via 'Sil.app' in the top-level project folder"

# build native macOS app (debug variant)
[group('development')]
debug-build-macos-app:
    (cd src && make -f Makefile.cocoa OPT="-O0 -g -fsanitize=address -fsanitize=undefined" clean install) || exit 1
    @echo "Run the game (debug build) via 'Sil.app' in the top-level project folder"

# run Sil-Q as console binary (ASCII mode)
[group('app')]
run-console:
    ./sil

# run Sil-Q as console Linux binary (ASCII mode)
[group('app')]
run-linux-console: run-console

# run Sil-Q as console macOS binary (ASCII mode)
[group('app')]
run-macos-console: run-console

# run Sil-Q as a native macOS app
[group('app')]
run-macos-app:
    open ./Sil.app
