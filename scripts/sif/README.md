# Fast-loading Apptainer SIF for the spatial-brain env

The pixi env is ~52k small files on Ceph, so cold Python imports do tens of
thousands of network round-trips (50–120 s). Packed into a **single SIF file**,
a cold load is one ~1 GB sequential read and imports become CPU-bound (~26 s for
the full scanpy/squidpy/torch/spatialdata/sopa/cellpose stack). Bonus: 52k inodes
→ 1, and the Jupyter kernel becomes worktree-independent.

## Artifacts

| What | Where |
|---|---|
| Live SIF | `/shared/projects/tp_2630_ubordeaux_neuromics_184418/containers/marius/spatialbrain.sif` |
| Build job | `scripts/sif/build_sif.sbatch` |
| conda-pack tool env (one-time) | `.../projects/C15/pixi/tools` |

## Build / rebuild

```bash
sbatch scripts/sif/build_sif.sbatch          # or: pixi run build-sif
```

Rebuild only when pixi deps change. The job re-packs the pixi env, so it re-reads
the env off Ceph once (a parallel pre-warm step keeps this to ~10–20 min instead
of ~60). It writes to `spatialbrain.sif.new`, smoke-tests it, and only then swaps
it in — the live SIF stays intact if the build fails.

### One-time: the conda-pack tool env

```bash
/shared/software/miniconda/bin/mamba create -y \
  -p /shared/projects/tp_2630_ubordeaux_neuromics_184418/projects/C15/pixi/tools \
  -c conda-forge conda-pack python=3.11
```

## Use it

Shell:
```bash
SIF=/shared/projects/tp_2630_ubordeaux_neuromics_184418/containers/marius/spatialbrain.sif
apptainer exec --bind /shared "$SIF" python my_analysis.py
apptainer exec --bind /shared "$SIF" jupyter lab
```

Jupyter kernels — register with `pixi run install-kernel-sif` (done by
`cluster_setup.sh`):
- **Spatial Brain (SIF)** — the kernel **students should use**. Self-contained and
  clone-agnostic (baked `spatialbrain` package, fixed SIF path); template in
  `scripts/sif/kernel/kernel.json`.
- **Spatial Brain (SIF, dev)** — **instructor-only**, not registered for students:
  it prepends *one specific checkout's* `src/` to `PYTHONPATH` so live edits to
  `src/spatialbrain` take effect without a rebuild. Because that path is
  per-clone, it must not be shared as-is. Create it manually and point
  `PYTHONPATH` at your own checkout.

## Add a package without rebuilding

Layer a writable overlay on the read-only SIF (works rootless here):
```bash
apptainer overlay create --size 2048 ~/sb-extras.img
apptainer exec --overlay ~/sb-extras.img --bind /shared "$SIF" pip install <pkg>
```
For a permanent addition, add it to `pixi.toml`, then rebuild the SIF.

## Why it's built the way it is (cluster constraints)

- **No `%post` / `--fakeroot`** — this account has no `/etc/subuid` mapping, so
  fakeroot builds fail. We build `%post`-free: base sandbox → `conda-pack` the
  pixi prefix into `/opt/env` → `conda-unpack` inside a `--writable` sandbox →
  squash. All rootless.
- **Env at `/opt/env`, not `/shared`** — the cluster force-binds `/shared`,
  `/shared/software`, `/shared/ifbstor1`, which would shadow anything baked under
  `/shared`. We also create those mountpoints in the sandbox so runtime binds work.
- **conda-unpack before stripping the editable `.pth`** — the editable
  `spatialbrain` install is in conda-unpack's rewrite manifest, so it must exist
  when conda-unpack runs; we strip it and copy the real `src/spatialbrain`
  (keeping its dist-info so `version("spatialbrain")` works) only afterward.
- **Node-local scratch is ephemeral** — it vanishes when the holding Slurm job
  ends. For a quick metadata/content fix, rebuild *from the SIF*
  (`apptainer build --sandbox sbx spatialbrain.sif` → edit → re-squash); it's one
  file and node-independent. Always submit the full build as a normal `sbatch`
  (queues on any free node) — never `srun -w <node>` targeting a busy node.
