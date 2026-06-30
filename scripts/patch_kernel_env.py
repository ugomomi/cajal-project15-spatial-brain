"""Patch the 'spatialbrain' Jupyter kernel so the conda env's libstdc++ loads first.

Why: manylinux PyPI wheels (notably torch) declare no path to the conda env in their
RUNPATH, so when they need ``libstdc++.so.6`` the loader falls back to the *system*
``/lib/x86_64-linux-gnu/libstdc++.so.6`` (older) and pins it for the whole process.
A later import that needs a newer C++ ABI — e.g. ``sqlite3`` → ``libicui18n`` needing
``CXXABI_1.3.15`` (pulled in by ``liana``) — then fails with "version not found".
Prepending ``$PREFIX/lib`` to ``LD_LIBRARY_PATH`` makes the env's newer (backward-
compatible) libstdc++ win for every library in the process.

Run by the ``install-kernel`` pixi task, after ``ipykernel install`` (so ``sys.prefix``
is the active env). The equivalent fix for ``pixi run``/batch is ``[activation.env]``
in ``pixi.toml``.
"""

import json
import sys
from pathlib import Path

DEFAULT_KERNEL = Path.home() / ".local/share/jupyter/kernels/spatialbrain/kernel.json"


def main() -> int:
    # Optional arg: path to a kernel.json (used by tests); defaults to the installed one.
    kernel = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_KERNEL
    if not kernel.exists():
        print(f"kernel.json not found at {kernel} — run `ipykernel install` first")
        return 1
    spec = json.loads(kernel.read_text())
    libdir = f"{sys.prefix}/lib"
    env = spec.setdefault("env", {})
    # Prepend; keep any pre-existing value (Jupyter expands ${VAR}; if it doesn't, the
    # literal token is just an unreadable path the loader skips — libdir still wins).
    env["LD_LIBRARY_PATH"] = f"{libdir}:${{LD_LIBRARY_PATH}}"
    kernel.write_text(json.dumps(spec, indent=1) + "\n")
    print(f"patched {kernel}: LD_LIBRARY_PATH -> {env['LD_LIBRARY_PATH']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
