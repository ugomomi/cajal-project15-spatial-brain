#!/usr/bin/env bash
# OPTIONAL: build a personal pixi environment. You do NOT need this to run the course
# notebooks — that is what the SIF kernel from `scripts/cluster_setup.sh` is for. Use this
# only if you want to add/modify packages (`pixi add ...`) or use the pixi-based
# "Spatial Brain (Project 15)" dev kernel. A few minutes the first time. Run from anywhere:
#
#     bash scripts/build_pixi_env.sh
#
# Why a script: the cluster home (~) has a ~100,000-file (inode) quota that a scientific
# pixi/conda environment would exceed, so this puts the environment and all caches on the
# large project filesystem instead, then builds the env and registers the pixi dev kernel.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."   # repo root — pixi needs pixi.toml here

# --- project filesystem location (shared, 1,000,000-inode quota) ---
PROJ=/shared/projects/tp_2630_ubordeaux_neuromics_184418/projects/C15
PIXI_BASE="$PROJ/pixi"

echo ">> pixi caches/envs will live under: $PIXI_BASE"
mkdir -p "$PIXI_BASE"/{cache,uv-cache,tmp,pre-commit,envs}

# --- ensure pixi is installed and on PATH ---
if ! command -v pixi >/dev/null 2>&1; then
  if [ -x "$HOME/.pixi/bin/pixi" ]; then
    export PATH="$HOME/.pixi/bin:$PATH"
  else
    echo ">> installing pixi"
    curl -fsSL https://pixi.sh/install.sh | bash
    export PATH="$HOME/.pixi/bin:$PATH"
  fi
fi
echo ">> pixi $(pixi --version)"

# --- persist the cache/tmp redirects for future interactive shells (idempotent) ---
add_export() {
  grep -qF "export $1" "$HOME/.bashrc" 2>/dev/null || echo "export $1" >> "$HOME/.bashrc"
}
add_export "PIXI_CACHE_DIR=\"$PIXI_BASE/cache\""
add_export "UV_CACHE_DIR=\"$PIXI_BASE/uv-cache\""
add_export "TMPDIR=\"$PIXI_BASE/tmp\""
add_export "PRE_COMMIT_HOME=\"$PIXI_BASE/pre-commit\""

# --- and for this run ---
export PIXI_CACHE_DIR="$PIXI_BASE/cache"
export UV_CACHE_DIR="$PIXI_BASE/uv-cache"
export TMPDIR="$PIXI_BASE/tmp"
export PRE_COMMIT_HOME="$PIXI_BASE/pre-commit"

# --- durably redirect caches off home for NON-interactive shells too ---
# Slurm batch jobs and `bash -c` don't source ~/.bashrc, so the exports above never
# reach them and pixi/uv/conda fall back to home (~100k-inode quota) — a big install
# (e.g. torch) then blows it. These config-file / symlink redirects are read by the
# tools in *every* context, interactive or not.
mkdir -p "$PIXI_BASE/cache" "$PIXI_BASE/uv-cache" "$PIXI_BASE/conda/pkgs" \
         "$PIXI_BASE/conda/envs" "$HOME/.cache/rattler" "$HOME/.config/uv"
# pixi/rattler default cache dir has no config key for its root → symlink it
if [ ! -L "$HOME/.cache/rattler/cache" ]; then
  rm -rf "$HOME/.cache/rattler/cache"
  ln -s "$PIXI_BASE/cache" "$HOME/.cache/rattler/cache"
fi
# uv reads ~/.config/uv/uv.toml everywhere
printf 'cache-dir = "%s"\n' "$PIXI_BASE/uv-cache" > "$HOME/.config/uv/uv.toml"
# conda reads ~/.condarc everywhere (create-if-absent — don't clobber existing config)
if [ ! -f "$HOME/.condarc" ]; then
  printf 'pkgs_dirs:\n  - %s\nenvs_dirs:\n  - %s\n' \
    "$PIXI_BASE/conda/pkgs" "$PIXI_BASE/conda/envs" > "$HOME/.condarc"
fi

# --- build environments on the project filesystem, not in the repo / home ---
pixi config set detached-environments "$PIXI_BASE/envs"

# --- build + register the pixi dev kernel and git hooks ---
echo ">> pixi install (a few minutes the first time)"
pixi install
echo ">> registering the pixi dev kernel ('Spatial Brain (Project 15)'; slower cold-start)"
pixi run install-kernel
echo ">> installing git hooks (pre-commit)"
pixi run install-hooks

cat <<'DONE'

Pixi environment ready.
  - Open a NEW shell (or `source ~/.bashrc`) so the cache settings load.
  - You can now `pixi add --pypi <pkg>` to experiment, and use the pixi
    "Spatial Brain (Project 15)" kernel in OnDemand (it cold-starts slowly).
  - To run the course notebooks, the fast "Spatial Brain (SIF)" kernel from
    scripts/cluster_setup.sh is still the recommended choice.
DONE
