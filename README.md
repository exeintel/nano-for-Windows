# GNU nano 9.2 for Windows — Portable Builds (32/64-bit)

Portable builds of the **GNU nano 9.2** text editor for Windows, compiled from
the sources in this repository with minimal Windows-specific fixes.

License: **GNU General Public License, version 3.0** (see `COPYING` in this
directory and in each build folder).

---

## Ready-made portable versions

| Folder | Architecture | File |
|---|---|---|
| `nano-9.2-win64/` | 64-bit (x86_64) | `nano.exe` |
| `nano-9.2-win32/` | 32-bit (i686) | `nano.exe` |

Contents of each folder:

```
nano.exe    — the editor itself (statically linked, stripped)
nano.bat    — launcher: runs nano with HOME pointing at this folder
.nanorc     — configuration (settings + syntax highlighting includes)
syntax/     — 44 syntax highlighting files (*.nanorc)
COPYING     — full text of the GPL v3 license
```

### DLL libraries

**No extra DLLs are required.** The binaries are statically linked: ncurses
(wide-char, with the built-in Windows console driver `win32con`), the compiler
runtime, and all other dependencies are built into `nano.exe`.

`nano.exe` only uses **system DLLs of Windows** that ship with the OS:

* `api-ms-win-crt-*.dll` (UCRT — built into Windows 10/11)
* `KERNEL32.dll`, `USER32.dll`, `bcrypt.dll`

So there is nothing else to copy next to the executable — that is the
advantage of a static portable build.

### System requirements

* Windows 10 or Windows 11 (UCRT required, included in the system).
* The 32-bit version works on any x86/x64 Windows 10+;
  the 64-bit version requires x64.

### Usage

Option 1 — via the launcher (recommended: enables syntax highlighting):

```
portable\nano-9.2-win64\nano.bat myfile.txt
```

Option 2 — directly:

```
portable\nano-9.2-win64\nano.exe myfile.txt
```

When run directly, nano takes its settings from `%USERPROFILE%\.nanorc` if it
exists. The `nano.bat` launcher instead sets HOME to the folder containing
`nano.exe`, so the local `.nanorc` and `syntax/` are used.

File association: you can drag a file from Explorer onto `nano.bat`.

### Features

The full nano feature set: editing, cutbuffer, search/replace, syntax
highlighting, built-in file browser (M-G), UTF-8 support, mouse, multiple
buffers, history, macros, lock files, and more.

Notes for this build:

* UTF-8 — enabled (ncursesw with wide-char support).
* Formatter (M-F) — works: runs an external program via `spawnvp()`
  (see the patch in `text.c`).
* Speller/linter pipeline (`M-S`) — disabled: they need `fork()`+pipes,
  which do not exist on native Windows. Interactive spell-checking of
  marked text through an external word editor works.
* NLS (translations) — disabled (no libintl in this build).

---

## Changes made to the nano sources (for Windows)

All modifications were made under the GPL; the files remain GPL-compatible:

1. **`src/browser.c`** — `read_the_list()` rewritten as a single pass.
   Reason: gnulib on Windows replaces `DIR` with an opaque
   `struct gl_module` but does not provide a compatible `rewinddir()`,
   so the old code did not compile.
2. **`src/files.c`** — backup timestamps are taken from `st_atime`/`st_mtime`
   (the `st_atim`/`st_mtim` fields do not exist on mingw).
3. **`src/text.c`** — same for `st_mtim`; added a Windows implementation of
   `treat()` using `_spawnvp(_P_WAIT, …)` (formatter and interactive
   spell-checker); `#include <process.h>`.
4. **`src/utils.c`** — `get_homedir()`: if `HOME` is not set, `USERPROFILE`
   is used (the standard profile on Windows).

Additionally, patches were applied to ncurses 6.5 at build time (MIT license,
not shipped in the portable folders, only statically linked): disabling the
obsolete `wcrtomb` workaround for UCRT and fixing `MKfallback.sh` for empty
Windows command-line arguments.

---

## Rebuilding from sources (brief)

Toolchain: **llvm-mingw** (clang/UCRT, includes busybox with `sh` and GNU
`make`) + **ncurses 6.5** sources.

1. Build ncursesw (static) twice — for `x86_64-w64-mingw32` and
   `i686-w64-mingw32`:

   ```sh
   ../ncurses-6.5/configure --build=<triple> --host=<triple> \
     --prefix=<prefix> --with-shared --with-normal \
     --without-cxx --without-ada --without-manpage \
     --without-tests --without-progs \
     --enable-term-driver --enable-interop --enable-ext-mouse \
     CC=<triple>-clang AR=<triple>-ar RANLIB=<triple>-ranlib
   make -j1 && make install
   ```

2. Configure nano (example for x64):

   ```sh
   srcdir/configure --build=x86_64-w64-mingw32 --host=x86_64-w64-mingw32 \
     --disable-nls --enable-utf8 --enable-nanorc --enable-color \
     --enable-multibuffer --enable-browser --enable-help \
     --enable-comment --enable-extra --enable-formatter --disable-speller \
     CC=x86_64-w64-mingw32-clang \
     CPPFLAGS="-DNCURSES_STATIC -I<prefix>/include/ncursesw" \
     LDFLAGS="-L<dir-with-libncursesw.a> -L<prefix>/lib"
   make -C lib && make -C src
   ```

   Key points:

   * `-DNCURSES_STATIC` — otherwise the ncurses headers expect dllimport,
     while the library is static;
   * a directory containing only a copy of `libncursesw.a` listed first in
     `LDFLAGS` (`-L…`) forces the linker to pick the static version instead
     of `.dll.a`;
   * the `doc` directory is skipped (no `makeinfo`).

3. `strip` the binary, place it into `portable/…`, and add `.nanorc`,
   `nano.bat`, `syntax/`, `COPYING`.

Build quirks on a plain Windows system without MSYS2:

* `configure` looks for `grep`/`sed`/`awk` **without the `.exe` extension** —
  so pass `GREP=grep SED=sed AWK=awk` to configure;
* `--build=…` is required (config.guess does not recognize plain Windows);
* `SHELL` points to busybox `sh`;
* ncurses is built with `-j1` (parallel builds misbehave on Windows).

---

## License

GNU nano is licensed under the **GNU General Public License, version 3.0 or
later** — see `COPYING`. The modified nano sources are in this repository
(`src/browser.c`, `src/files.c`, `src/text.c`, `src/utils.c`).

ncurses 6.5 is licensed under the MIT license (statically linked into
`nano.exe`).

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
