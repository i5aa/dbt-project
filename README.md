# dbt-project

A dbt + Snowflake project that turns the [MovieLens](https://grouplens.org/datasets/movielens/) dataset (movies, ratings, tags and tag-genome scores) into a small analytics warehouse. Raw CSVs are loaded from S3 into Snowflake, then dbt cleans them in staging views and builds dimension, fact and mart tables on top.

## Tech stack

- **Snowflake** – data warehouse (`NETFLIX` database, `RAW` schema for raw data)
- **AWS S3** – source of the raw CSV files (`s3://netflixmoviedata`)
- **dbt Core 1.9** with the `dbt-snowflake` adapter
- **dbt_utils 1.3.0** – used for surrogate keys in the snapshot

## Repository layout

```
dbt-project/
├── EnvConfig.sql                     # Snowflake role, warehouse, user, database setup + local setup notes
├── IngestingfromExternalLocation.sql # Creates the S3 stage and loads raw_* tables with COPY INTO
├── split_csv.py                      # Splits a large CSV into ~150 MB parts (for uploading big files)
└── netflix/                          # The dbt project
    ├── dbt_project.yml
    ├── packages.yml
    ├── models/
    │   ├── sources.yml               # Source definitions for the NETFLIX.RAW tables
    │   ├── staging/                  # src_* views: rename columns, convert timestamps
    │   ├── dim/                      # Dimension tables
    │   ├── fct/                      # Fact tables
    │   └── mart/                     # Business-facing tables
    ├── seeds/movie_release_date.csv  # Sample release dates for a few movies
    └── snapshots/tags_snap.sql       # SCD Type 2 history of user tags
```

## Data flow

```
S3 CSVs ──COPY INTO──▶ NETFLIX.RAW.raw_*  ──▶ staging (views) ──▶ dim / fct (tables) ──▶ mart
                                                    │
                                                    └──▶ snapshots.tags_snap
```

### Raw tables (`NETFLIX.RAW`)

| Table | Columns |
|---|---|
| `raw_movies` | movieId, title, genres |
| `raw_ratings` | userId, movieId, rating, timestamp |
| `raw_tags` | userId, movieId, tag, timestamp |
| `raw_genome_scores` | movieId, tagId, relevance |
| `raw_genome_tags` | tagId, tag |
| `raw_links` | movieId, imdbId, tmdbId |

### Models

| Layer | Model | Materialization | What it does |
|---|---|---|---|
| staging | `src_movies`, `src_ratings`, `src_tags`, `src_genomescore`, `src_genometags`, `src_links` | view | Rename columns to snake_case; convert Unix timestamps to `TIMESTAMP_LTZ` |
| dim | `dim_movies` | table | Clean title (`INITCAP(TRIM())`), split genres into an array |
| dim | `dim_genome_tags` | table | Clean tag names |
| dim | `dim_users` | table | Distinct users from ratings and tags |
| dim | `dim_movies_with_tags` | ephemeral | Movies joined with genome tags and relevance scores |
| fct | `fct_genome_scores` | table | Movie–tag relevance scores, rounded to 4 decimals |
| fct | `fct_ratings` | incremental | Non-null ratings; only new rows (by `rating_timestamp`) are added on each run |
| mart | `mart_moviereleases` | table | Ratings flagged with whether a release date is known (from the seed) |

### Seed and snapshot

- **`movie_release_date`** – a small CSV of `movie_id, release_date`, loaded with `dbt seed`.
- **`tags_snap`** – a timestamp-based snapshot of `src_tags` stored in the `snapshots` schema. It keeps a history of tag changes and records hard deletes, with a surrogate key built from `user_id`, `movie_id` and `tag`.

## Getting started

### 1. Set up Snowflake

Run `EnvConfig.sql` as `ACCOUNTADMIN` in a Snowflake worksheet. It creates:

- the `TRANSFORM` role
- the `COMPUTE_WH` warehouse
- a `dbt` user (change the password before running it)
- the `NETFLIX` database and `NETFLIX.RAW` schema

### 2. Load the raw data

Fill in your AWS key and secret in `IngestingfromExternalLocation.sql`, then run it to create the `netflixstage` stage and load the six `raw_*` tables.

If a source CSV is too large to upload, split it first with `split_csv.py` (set `input_path` and `output_dir` at the top of the script):

```bash
python split_csv.py
```

### 3. Install dbt

```bash
# Windows
virtualenv venv
venv\Scripts\activate

# macOS / Linux
virtualenv venv
. venv/bin/activate

pip install dbt-snowflake==1.9.0
```

### 4. Configure the dbt profile

Create `~/.dbt/profiles.yml` (on Windows: `%USERPROFILE%\.dbt\profiles.yml`):

```yaml
netflix:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: <your_account_identifier>
      user: dbt
      password: <your_password>
      role: TRANSFORM
      warehouse: COMPUTE_WH
      database: NETFLIX
      schema: RAW
      threads: 4
```

Check the connection:

```bash
cd netflix
dbt debug
```

### 5. Build the project

```bash
cd netflix
dbt deps       # install dbt_utils
dbt seed       # load movie_release_date.csv
dbt run        # build all models
dbt snapshot   # update tags_snap
dbt test       # run tests
```

Useful extras:

```bash
dbt run --select fct_ratings --full-refresh   # rebuild the incremental model from scratch
dbt docs generate && dbt docs serve           # browse the docs and lineage graph
```
