# Compiling Instructions

## Preparation (for all platforms)

**Step 0**: Download and extract the Sil-Q source code.

- Unzip the file `Sil-src.zip`. It will become a folder called `Sil`, which
  contains sub-folders called `lib/` and `src/`.
  - The `src/` folder contains all the source code.
  - The `lib/` folder contains other files that the game uses. **Once compiled,
    the Sil-Q game (like `sil.exe` on Windows) still requires the files and
    folders under the `lib/` directory.**
- Move the `Sil` folder to wherever you want to keep it.
- When you are done compiling the source code as per the instructions below, the
  game will be automatically installed in the `Sil` folder as well.

## Linux or Unix with gcc

There are several different unix setups for Sil-Q:

- X11: Allows multiple windows, has correct colours.
- GCU: Works in a terminal using 'curses', has only 16 or 8 colours.
- CAP: Works even in old terminals, but is monochrome.

**Step 1**: Modify the Makefile to match your system.

- Edit Makefile.std in the src directory.
- Look for the section listing multiple "Variations".
- Choose the variation that you like best.
- Uncomment that section's code by removing the `#` character at the start of
  the lines.
- Comment out the default section by prefixing the respective lines with `#`.

**Step 2**: Compile Sil-Q. Open a terminal in the top-level directory of Sil-Q.

    ```shell
    # Go to the src/ directory
    $ cd src

    # Compile the sources
    $ make -f Makefile.std install
    ```

**Step 3**: Run Sil-Q via the `sil` binary in the top-level directory. Note that
you still need the `lib/` directory to run Sil-Q. It must be located in the same
directory as the `sil` binary.

    ```shell
    # Go back to top-level directory
    $ cd ..

    # Run the Sil-Q binary to start the game
    $ ./sil

Enjoy!

## Windows with Cygwin

**Step 1**: Get the free Cygwin compiler.

- Download the free Cygwin compiler. It provides a shell interface very similar
  to a normal Unix/Linux shell with many useful tools. Install it and start the
  Cygwin terminal. Make sure to get the 32 bit version (the 64 bit version may
  work, but has been tested less than the 32 bit version).
- Note: Make sure `make` and the mingw C compiler are installed, because they
  may not be included in your Cygwin default installation.

**Step 2**: Compile Sil-Q. Open a terminal in the top-level directory of Sil-Q.

    ```shell
    # In the Cygwin terminal, go to the src/ directory
    $ cd src/

    # Compile the sources
    $ make -f Makefile.cyg install
    ```

**Step 3**: Run Sil-Q via the `sil.exe` binary in the top-level directory. Note
that you still need the `lib/` directory to run Sil-Q. It must be located in the
same directory as `sil.exe`.

    ```shell
    # Go back to top-level directory
    $ cd ..

    # Run the Sil-Q executable to start the game
    $ ./sil.exe

Enjoy!

## Windows with Visual Studio 2022 (experimental, tested with Sil-Q on MSVC 2022)

> WARNING: This is a very new and very raw port, and it requires testing.

**Step 1**: Install Microsoft Visual Studio 2022.

**Step 2**: Compile Sil-Q.

- Assuming you have MSVC 2022, this should be as simple as selecting "Debug" or
  "Release", opening `sil-q.sln` in the `msvc2019/` directory, and selecting
  "Build Solution" from the Build menu.

**Step 3**: Run Sil-Q via the `sil.exe` binary in the top-level directory. Note that
you still need the `lib/` directory to run Sil-Q. It must be located in the same
directory as `sil.exe`.

Enjoy!

## macOS with Xcode

> These instructions were tested with Xcode 11.6 on macOS 10.15.5 (Catalina) and
> with Xcode 26.2 on macOS 26.2 (Tahoe).

**Step 1**: Install Xcode from the Apple App Store.

**Step 2**: Compile Sil-Q. Open a terminal in the top-level directory of Sil-Q.

> NOTE: Before building for a different set of architectures (Apple Silicon vs.
> Intel), run `make -f Makefile.cocoa clean` to clean up any object files that
> may not match your new set of selected architectures.

    ```shell
    # Go to the src/ directory
    $ cd src

    # Option 1: Compile the sources for Apple Silicon Macs (M1/M2/M3/M4).
    #           *** Requires Xcode 12.2 or later. ***
    $ make -f Makefile.cocoa ARCHS=arm64 install

    # Option 2: Compile the sources for Intel-based Macs
    $ make -f Makefile.cocoa install

    # Option 3: Create a universal application that will run natively on
    #           both Apple Silicon and Intel-based Macs.
    #           *** Requires Xcode 12.2 or later. ***
    $ make -f Makefile.cocoa ARCHS='x86_64 arm64' install
    ```

The compilation generates a macOS application, `Sil.app`, in the top-level
directory of Sil-Q (the parent directory of `src/`). You may move `Sil.app` to
wherever you like, such as your Mac's `Applications` folder.

**Step 3**: Run Sil-Q via the `Sil.app` application.

In a Finder window, navigate to where you placed `Sil.app`. Then double-click on
it to run it.

> NOTE: If you are on macOS 10.15 or later and haven't run Sil-Q before, you
> will see macOS dialog window about granting Sil-Q access to your `Documents`
> folder. You must approve this access, because it is required by Sil-Q as it
> stores its savefiles (your in-game characters), the high score file, and
> additional game data in the folder `Documents/Sil/`.

Enjoy!
