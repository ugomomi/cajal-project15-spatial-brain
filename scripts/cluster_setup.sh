#!/usr/bin/env bash
# FAST, EASY one-time setup on the IFB Core Cluster. Run from the repo root:
#
#     bash scripts/cluster_setup.sh
#
# There is NOTHING to build. The whole scientific stack (scanpy, squidpy, spatialdata,
# sopa, cellpose, proseg, cellmapper, ...) is prebuilt in ONE shared Apptainer image; this
# script just registers a Jupyter kernel that points at it, plus the shared Baysor binary
# that Level 1 needs. Takes seconds. Then open OnDemand and pick the "Spatial Brain (SIF)"
# kernel.
#
# Curious, or want to add/modify packages? Build a personal pixi env instead (optional,
# a few minutes): bash scripts/build_pixi_env.sh
set -euo pipefail

PROJ=/shared/projects/tp_2630_ubordeaux_neuromics_184418/projects/C15
SIF=/shared/projects/tp_2630_ubordeaux_neuromics_184418/containers/marius/spatialbrain.sif
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # scripts/ -> repo root
KSRC="$REPO/scripts/sif/kernel/kernel.json"
KDEST="$HOME/.local/share/jupyter/kernels/spatialbrain-sif"

# --- register the container-backed Jupyter kernel (no pixi, no build) ---
# The kernelspec just runs `apptainer exec <shared SIF> python -m ipykernel`, so all we do
# is copy it where Jupyter looks for user kernels. OnDemand's JupyterLab then lists it.
echo ">> registering the 'Spatial Brain (SIF)' Jupyter kernel"
[ -f "$KSRC" ] || { echo "ERROR: $KSRC missing — run this from your clone of the repo."; exit 1; }
[ -e "$SIF" ] || echo "   WARNING: shared SIF not found at $SIF (the kernel points here) — tell the instructor."
mkdir -p "$KDEST"
cp "$KSRC" "$KDEST/kernel.json"
echo "   installed -> $KDEST/kernel.json"

# --- Baysor segmentation binary (shared, not per-student) — needed by Level 1 ---
# CellPose and Proseg are already inside the SIF, so they need no setup. Baysor is the
# exception: a 1.3 GB prebuilt Julia binary staged once on the project filesystem (NOT in
# the SIF). Sopa locates it on PATH or at ~/.julia/bin/baysor; we symlink the shared copy
# there (~1 inode) so nobody has to download or build it.
echo ">> linking shared Baysor binary into ~/.julia/bin"
if [ -e "$PROJ/software/bin/baysor" ]; then
  mkdir -p "$HOME/.julia/bin"
  ln -sf "$PROJ/software/bin/baysor" "$HOME/.julia/bin/baysor"
  "$HOME/.julia/bin/baysor" --version >/dev/null 2>&1 \
    && echo "   Baysor $("$HOME/.julia/bin/baysor" --version 2>/dev/null) ready" \
    || echo "   WARNING: Baysor symlink created but did not run — tell the instructor."
else
  echo "   NOTE: shared Baysor binary not found at $PROJ/software/bin/baysor — skipping (ask the instructor)."
fi

cat <<'DONE'

Setup complete — nothing was built.
  Open Open OnDemand JupyterLab and pick the "Spatial Brain (SIF)" kernel:
    https://ondemand.cluster.france-bioinformatique.fr
  It loads the shared container in seconds. That is all you need to run the notebooks.

  Optional (only if you want to add/modify packages): build a personal pixi env with
    bash scripts/build_pixi_env.sh
DONE
