# Pending env changes for the next SIF rebuild

Running list of changes that are committed in the repo but **not yet baked** into
the live container (`…/containers/marius/spatialbrain.sif`). The SIF is a snapshot
of the pixi env + `src/spatialbrain`, so these only take effect after a rebuild.

**To bake them in:**

```bash
# dependency change? update the pixi env first:
pixi install
# then rebuild + swap in the SIF (~10–20 min; see scripts/sif/README.md):
pixi run build-sif
```

Tick items off (or clear the list) once a rebuild lands them.

## Pending

_(none — all committed env changes are baked into the live SIF.)_

## Last baked

- 2026-07-01 — rebuild: baked the `FilePaths` runtime repo-root resolution
  (`src/spatialbrain/_constants.py`, [#9](https://github.com/quadbio/cajal-project15-spatial-brain/pull/9)).
  Verified in-container: from a repo cwd `FilePaths.DATA` now resolves to the writable
  `data/` (not inside `/opt/env`), and `$SPATIALBRAIN_ROOT` override is honored. No
  dependency change, so the pixi env was reused as-is (source-only re-bake).
- 2026-07-01 — initial build (scanpy 1.12.1, torch 2.8.0+cpu).
