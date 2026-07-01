#!/usr/bin/env bash
#SBATCH -J spatialbrain-sif
#SBATCH -A tp_2630_ubordeaux_neuromics_184418
#SBATCH -p fast
#SBATCH -c 16
#SBATCH --mem 32G
#SBATCH -t 03:00:00
#SBATCH -o sif-build-%j.log
set -euo pipefail
#
# Build a single-file, fast-loading Apptainer SIF from this project's pixi env.
#
# WHY: the pixi env is ~52k small files on Ceph; cold Python imports do 52k
# network round-trips (50-120 s). Packed into one SIF, a cold load is one
# ~1 GB sequential read (seconds) and imports become CPU-bound (~26 s for the
# full stack). It also collapses 52k inodes -> 1 and makes the Jupyter kernel
# worktree-independent. See scripts/sif/README.md for the full story.
#
# ROOTLESS BUILD: this cluster has no /etc/subuid mapping, so --fakeroot / %post
# builds FAIL. We therefore build %post-free: base sandbox -> conda-pack the pixi
# prefix into /opt/env -> conda-unpack inside a writable sandbox -> squash.
#
# USAGE:   sbatch scripts/sif/build_sif.sbatch
# Overrides (env vars):
#   SPATIALBRAIN_PREFIX    source pixi env prefix (default: most recent build)
#   SPATIALBRAIN_REPO_SRC  repo src/ to bake as the `spatialbrain` package
#   SPATIALBRAIN_SIF       output SIF path

PROJ=/shared/projects/tp_2630_ubordeaux_neuromics_184418
CONDA_PACK="$PROJ/projects/C15/pixi/tools/bin/conda-pack"   # one-time setup: see README

REPO_SRC="${SPATIALBRAIN_REPO_SRC:-$(git -C "${SLURM_SUBMIT_DIR:-$PWD}" rev-parse --show-toplevel)/src}"
# pixi's detached env for this project is worktree-hashed; default to the newest.
PREFIX="${SPATIALBRAIN_PREFIX:-$(ls -td "$PROJ"/pixi/envs/spatialbrain-*/envs/default 2>/dev/null | head -1)}"
SIF="${SPATIALBRAIN_SIF:-$PROJ/containers/marius/spatialbrain.sif}"

[ -x "$CONDA_PACK" ] || { echo "ERROR: conda-pack missing at $CONDA_PACK (see README: one-time tool env)"; exit 1; }
[ -d "$PREFIX" ]     || { echo "ERROR: pixi env prefix not found: $PREFIX"; exit 1; }
[ -d "$REPO_SRC/spatialbrain" ] || { echo "ERROR: repo src not found: $REPO_SRC/spatialbrain"; exit 1; }
mkdir -p "$(dirname "$SIF")"
echo ">> node=$(hostname)"; echo ">> prefix=$PREFIX"; echo ">> src=$REPO_SRC"; echo ">> out=$SIF"

# node-local scratch: fast, and short paths (AF_UNIX socket limit)
SCR=/tmp/sifbuild-$USER-${SLURM_JOB_ID:-$$}
SBX=$SCR/sbx
export APPTAINER_CACHEDIR=$SCR/apc APPTAINER_TMPDIR=$SCR/apt
mkdir -p "$APPTAINER_CACHEDIR" "$APPTAINER_TMPDIR"

echo ">> [0/6] parallel pre-warm the env's page cache (hides Ceph small-file latency)"
find "$PREFIX" -type f -print0 | xargs -0 -P 32 -n 64 cat > /dev/null 2>&1 || true

echo ">> [1/6] base sandbox (ubuntu + env vars; rootless, no %post)"
cat > "$SCR/spatialbrain.def" <<'DEF'
Bootstrap: docker
From: ubuntu:22.04
%environment
    export PATH=/opt/env/bin:$PATH
    export LD_LIBRARY_PATH=/opt/env/lib:$LD_LIBRARY_PATH
%runscript
    exec /opt/env/bin/python "$@"
%labels
    Project CAJAL Neuromics 2026 - Project 15 (spatial brain)
    Source pixi env, conda-packed
DEF
apptainer build --force --sandbox "$SBX" "$SCR/spatialbrain.def"

echo ">> [2/6] conda-pack pixi env -> sandbox /opt/env (relocatable, no archive)"
"$CONDA_PACK" -p "$PREFIX" --format no-archive \
    --ignore-editable-packages --ignore-missing-files -j -1 \
    -o "$SBX/opt/env"

echo ">> [3/6] bind mountpoints (cluster force-binds /shared*)"
mkdir -p "$SBX"/shared "$SBX"/shared/{software,ifbstor1,projects,bank,home}

echo ">> [4/6] conda-unpack inside sandbox (rewrite prefix -> /opt/env)"
# MUST run before stripping the editable spatialbrain .pth (it's in the manifest).
apptainer exec --writable --no-home "$SBX" /opt/env/bin/conda-unpack

echo ">> [5/6] bake spatialbrain (drop editable .pth, keep dist-info, copy real src)"
SP=$SBX/opt/env/lib/python3.12/site-packages
rm -f  "$SP"/_editable_impl_spatialbrain.pth
rm -rf "$SP"/spatialbrain
cp -r "$REPO_SRC/spatialbrain" "$SP/spatialbrain"

echo ">> [6/6] squash -> NEW SIF, smoke-test, then swap in (keeps old SIF until pass)"
apptainer build --force "$SIF.new" "$SBX"
apptainer exec "$SIF.new" python -c \
  "import scanpy,squidpy,torch,spatialdata,sopa,cellpose,spatialbrain; print('IMPORT OK spatialbrain',spatialbrain.__version__,'| scanpy',scanpy.__version__)"
mv -f "$SIF.new" "$SIF"
ls -la "$SIF"
rm -rf "$SCR"
echo ">> DONE: $SIF"
