#!/bin/bash
set -e

# Environment variables for benchmarking
export DATABASE_URL=postgres://postgres:postgres@localhost:5432/postgres
export NONE_DATABASE_URL=postgres://postgres:postgres@localhost:5432/none
export NEON_DATABASE_URL=postgres://postgres:postgres@localhost:5432/neon
export PGVECTOR_DATABASE_URL=postgres://postgres:postgres@localhost:5432/pgvector
export LANTERN_DATABASE_URL=postgres://postgres:postgres@localhost:5432/lantern

# Benchmarking parameters
BASE_PARAMS="--extension lantern --dataset sift --N 10k"
INDEX_PARAMS="--m 4 --ef_construction 128 --ef 10"
PARAMS="$BASE_PARAMS $INDEX_PARAMS --K 5"

# Settings
SKIP_SETUP=0
PRINT_ONLY=0
BENCHMARK_DIR="benchmark"
if [ -d "$BENCHMARK_DIR" ]; then
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --skip-setup) SKIP_SETUP=1 ;;
            --print-only) PRINT_ONLY=1 ;;
        esac
        shift
    done
fi

# Pull benchmarking repo
if [ ! -d "$BENCHMARK_DIR" ]; then
    git clone https://github.com/lanterndata/benchmark "$BENCHMARK_DIR"
    cd "$BENCHMARK_DIR"
else
    cd "$BENCHMARK_DIR"
    if [ "$SKIP_SETUP" -ne 1 ] && [ "$PRINT_ONLY" -ne 1 ]; then
        git pull origin main
    fi
fi

# Install requirements
if [ "$SKIP_SETUP" -ne 1 ] && [ "$PRINT_ONLY" -ne 1 ]; then
    pip install -r core/requirements.txt --break-system-packages
    pip install -r external/requirements.txt --break-system-packages
fi

# Run setup
if [ "$SKIP_SETUP" -ne 1 ] && [ "$PRINT_ONLY" -ne 1 ]; then
    python3 -m core.setup --datapath /tmp/benchmark_data $BASE_PARAMS
else
    echo "Skipping data setup"
fi

# Run benchmarks
if [ "$PRINT_ONLY" -ne 1 ]; then
    python3 -m external.run_benchmarks $PARAMS
fi

# Render benchmarks
python3 -m external.show_benchmarks $PARAMS
python3 -m external.validate_benchmarks $PARAMS
python3 -m external.get_benchmarks_json $PARAMS > /tmp/benchmarks-out.json