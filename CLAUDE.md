# CLAUDE.md — Project 15

Single-cell / spatial analysis on the IFB Core Cluster, managed with pixi.

## Cluster invariants
- Shared project folder (large quota): `/shared/projects/tp_2630_ubordeaux_neuromics_184418`.
- Home (`~`) has a ~100,000-file (inode) quota — too small for a scientific env. The (optional)
  pixi environment, caches, and raw data therefore live on the **project filesystem**, not home
  (configured by `scripts/build_pixi_env.sh`). The default student path builds no env: run
  `scripts/cluster_setup.sh` to register the shared SIF-container kernel (seconds, nothing built).
- Raw data is staged once on the project filesystem (shared, not duplicated per person);
  your own processed outputs go in the repo's `data/`.
- Run on compute nodes, never the login node — via Open OnDemand apps or Slurm (`srun`/`sbatch`).

## Environment
- pixi: deps in `pixi.toml`, pinned in `pixi.lock`. Add packages PyPI-first
  (`pixi add --pypi <pkg>`; conda only for hard-to-build compiled deps), then commit both files.

## Paper & reference code
- Dataset paper: Wang et al., *Nature* 647:169–178 (2025), "Molecular and cellular dynamics of
  the developing human neocortex" (Kriegstein lab) — DOI 10.1038/s41586-024-08351-7. snMultiome
  + MERSCOPE spatial. **Withheld from students until the Level 2 reveal.**
- Authors' analysis code: https://github.com/complexdisease/Human_Cortex_Dev_Multiome (mostly R;
  spatial work — neighbourhood enrichment, NCEM — in `MERFISH_nhood_and_NCEM/`, GRNs in
  `SCENICplus/`). Reference for reproducing Fig. 2, not to hand to students before L2.
- Teaching outline / level plan: `docs/teaching_outline.md`.

## Docs
- IFB cluster: https://doc.cluster.france-bioinformatique.fr/  ·  Project setup: README.md
