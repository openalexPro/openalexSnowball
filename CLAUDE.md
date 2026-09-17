# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Developer Skill

All development in this repository follows the R package developer skill. Read and apply:

- `skills/r-package-developer/SKILL.md` — workflow phases, non-negotiable rules, governance
- `skills/r-package-developer/references/checklist.md` — pre-commit/merge execution gate
- `skills/r-package-developer/references/commit-template.md` — commit message structure
- `skills/r-package-developer/references/branch-protection-baseline.md` — branch rules
- `skills/r-package-developer/references/agent-r-guidance.md` — R-specific agent guidance

To sync the skill from upstream: `bash skills/r-package-developer/scripts/sync-from-github.sh`

## Project Overview

**openalexSnowball** is an R package implementing citation network "snowball searches" on the OpenAlex academic graph. Starting from seed papers (keypapers), it follows citation links outward to retrieve papers that cite or are cited by the seeds, building a network graph stored as Apache Parquet files for memory-efficient on-disk processing.

## Common Commands

```r
# Load package for interactive development
devtools::load_all()

# Run full R CMD check
devtools::check()

# Run all tests
devtools::test()

# Run a single test file
devtools::test(filter = "pro_snowball")

# Test coverage
covr::package_coverage()

# Rebuild documentation (Roxygen2)
devtools::document()
```

## Architecture

### Core Pipeline (5 exported functions)

1. **`pro_snowball()`** — Top-level orchestrator. Accepts `identifier` (OpenAlex IDs) or `doi` (mutually exclusive). Returns path to the output directory.

2. **`pro_snowball_get_nodes()`** — Phase 1: collects the keypapers and their citing/cited works, and assembles `output/nodes/`, partitioned by `relation` (`keypaper`, `citing`, `cited`). Two backends:
   - **API** (default): `openalexPro::pro_query()` → `pro_request()` (JSON) → `pro_request_parquet()`.
   - **Snapshot** (`snapshot = <path>`): entirely offline, via `openalexSnapshot::lookup_by_id()`, `get_citing()` and `get_cited()`. Requires the corpus index, citation index, and the DOI index if keypapers are given as DOIs.

3. **`pro_snowball_extract_edges()`** — Phase 2: creates a `read_parquet` view over `nodes/`, executes `inst/extract_edges.sql`, and writes `output/edges/` partitioned by `edge_type`.

4. **`read_snowball()`** — Reads a completed snowball directory; returns `nodes` and `edges` as Arrow Datasets (default) or tibbles (`return_data = TRUE`). Filters by `edge_type`; `meta = TRUE` adds the provenance sidecar.

5. **`snowball_duckdb_config()`** — Builds the DuckDB settings used by the two connections the pipeline opens. See *DuckDB configuration* below.

### Node roles

`id` is a key in `nodes/` — one row per work, whichever backend produced it. Because a work can hold more than one role at once, the roles are three independent booleans: **`is_keypaper`**, **`is_citing`**, **`is_cited`**. Any combination can be `TRUE`.

`relation` is kept as the hive partition key but records only the **highest-precedence** role (`keypaper` > `citing` > `cited`), so it is lossy: `relation == "cited"` does *not* find every cited work. Filter on the booleans; use `relation` for partition pruning.

### Edge Classification (in `inst/extract_edges.sql`)

Three **mutually exclusive** edge types — the `CASE` falls through, so a core edge is never also reported as extended:
- `core` — at least one endpoint is a keypaper, and both endpoints are in the dataset
- `extended` — both endpoints are in the dataset, and neither is a keypaper
- `outside` — at least one endpoint is external to the dataset

`read_snowball(edge_type = c("core", "extended"))` is therefore a union of disjoint sets, not a widening.

### Node assembly is two passes, deliberately

`.assemble_nodes()` must not put the wide nested works columns through a blocking operator. Computing the role flags and the de-duplication in window functions (as 0.12.1/0.13.0 did) pushed all ~51 columns — `abstract`, `abstract_inverted_index` as `MAP(VARCHAR, BIGINT[])`, `authorships`, `locations`, `topics` — through four of them, and a 2137-keypaper run hit a 28.7 GiB memory limit.

- **Pass 1** aggregates `(id, relation)` plus the synthetic `filename` / `file_row_number` into one row per work: the three flags and the physical address of the precedence winner, via `min(struct_pack(...))` (STRUCT comparison is lexicographic by field position, so one aggregate replaces all four windows and gives a total, deterministic tie-break).
- **Pass 2** scans the wide data once per relation and inner-joins that narrow table on the row address — 1:1, so the payload only ever travels the streaming probe side.

Three details are load-bearing: all statements share one `read_parquet(union_by_name = true)` spec (relations are selected with `WHERE`, never by narrowing the file list, because `read_corpus()` infers the schema from the first fragment); `hive_partitioning = false` (otherwise `query=chunk_N/` levels make the node schema depend on the keypaper count); and no `PARTITION_BY` (its writer buffers 524,288 rows per thread with no byte cap).

### DuckDB configuration

Both connections go through `.osb_con()`. DuckDB's defaults are wrong for a package people run several of at once: `memory_limit` is ~80% of RAM **per instance**, and `temp_directory` is `.tmp` *relative to the working directory*, so concurrent callers share one spill directory and corrupt each other's spill files.

Defaults here: `preserve_insertion_order = FALSE`, a private per-call/per-stage spill directory under `tempdir()`, and a budget of half of physical RAM divided by a declared `concurrency`:

```r
options(openalexSnowball.duckdb_config = list(concurrency = 4))
```

Settings resolve **per field** (argument > option > package default), so setting one does not discard the others. Unknown field names are an error. Leave `partitioned_write_max_open_files` alone: `nodes/` and `edges/` have three partitions each.

### Resume

`pro_snowball(resume = TRUE)` keeps an existing `output` and skips stages recorded in `.osb_done/`; within fetching, only unfinished query chunks are re-requested. `_snowball_run.parquet` records the parameters that define the snowball, and resuming with a different seed set, `snapshot`, `endpoint`, `max_results` or `select` is a hard error — `workers`, `verbose` and `duckdb_config` may differ freely.

Note the default `output` is a `tempfile()` and does not survive the session, so cross-session resume needs an explicit persistent `output =`.

### Key Design Patterns

- **On-disk processing**: Arrow + DuckDB throughout; data is never fully loaded into R memory during the pipeline.
- **Dependency on openalexPro / openalexSnapshot**: `openalexPro` (>= 0.12.0) handles API communication and JSON→Parquet conversion; `openalexSnapshot` (>= 0.3.1) provides the offline backend. openalexSnowball orchestrates both.
- **NSE**: Uses `rlang` `.data` and `.env` pronouns in dplyr chains.

## Testing

Tests live in `tests/testthat/` and need no network. Nothing is skipped on CI.

- **API path** — VCR cassettes in `tests/fixtures/vcr/`. `helper_vcr.R` configures paths and filters `api_key` / `Authorization`. Record new cassettes rather than making live requests. Note the request URLs are a function of the *sorted* keypaper set (`.osb_keypaper_ids()` orders by `id`), so cassettes are stable across scan order and DuckDB versions.
- **Snapshot path** — `make_snapshot_fixture()` (`helper_snapshot.R`) builds a synthetic corpus in `tempdir()` via `openalexSnapshot`'s `make_tiny_corpus()` and then all three indexes. No real corpus needed.
- `test-006-assemble_nodes_memory.R` reproduces the 28.7 GiB OOM in seconds: a payload large in memory but tiny on disk, a 512 MB `memory_limit` and `max_temp_directory_size = '0KiB'` so it fails instead of spilling. It also asserts the invariant that matters — the assembly plan contains **no `WINDOW` operator**.
- `test-008-resume.R` covers resume end to end, including the regression test for the old `APPEND` (a second assembly must not double the rows).
- `test-005` ends with two overlapping `pro_snowball(snapshot=)` runs under `future::multisession`, the only test that exercises concurrency.
- Snapshot files are in `tests/testthat/_snaps/`. Do **not** snapshot `print()` of the nodes tibble: it includes the nested `authorships` struct type header, whose field order differs between DuckDB versions.

Comparison against `openalexR::oa_snowball()` is the correctness anchor (`test-004`, zero-diff).

## CI/CD

| Workflow | Trigger | Purpose |
|---|---|---|
| `R-CMD-check.yaml` | push to main/dev, PRs | Matrix check across macOS, Windows, Ubuntu × R versions |
| `test-coverage.yaml` | push to main/master, PRs | Codecov coverage reporting |
| `pkgdown.yaml` | — | Builds documentation site |
| `rhub.yaml` | — | R-hub comprehensive environment checks |

**Ecosystem dependencies are pinned to `@dev` in all three workflows**
(`github::openalexPro/openalexPro@dev`,
`github::openalexPro/openalexSnapshot@dev`). Without the pin, pak resolves
them from the *default* branch, where the versions are far below this
package's `Imports` floors, and dependency resolution fails before a single
test runs — which is exactly why this suite had never executed on CI before
0.15.0. **Drop the `@dev` pins once openalexPro >= 0.12.0 and
openalexSnapshot >= 0.3.1 reach `main`.**

## Notes

- Vignettes use Quarto (`.qmd`) with `execute: eval: false` to avoid live API calls during package builds.
- The `.vscode/settings.json` configures a DuckDB SQLTools connection for interactive SQL development against the in-memory DuckDB engine.
- Code and documentation in this repository have been generated with LLM assistance and reviewed by humans.
