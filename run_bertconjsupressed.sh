#!/bin/bash

# Usage: ./run_bertini_with_tail_stats.sh NUM_SAMPLES

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 NUM_SAMPLES"
    exit 1
fi

NUM_SAMPLES="$1"
INPUT_FILE="attempt6.input"
START_FILE="start_points"
PYTHON_SCRIPT="analyze_last_four_points.py"
OUTPUT_FILE="results.txt"

# Check required files
if [[ ! -f "$INPUT_FILE" || ! -f "$START_FILE" || ! -f "$PYTHON_SCRIPT" ]]; then
    echo "Error: Required file missing: $INPUT_FILE, $START_FILE, or $PYTHON_SCRIPT"
    exit 1
fi

echo "# File : Real solutions | TwoReal | ComplexConj" > "$OUTPUT_FILE"

for ((i=1; i<=NUM_SAMPLES; i++)); do
    PARAM_FILE="parameter_samples/final_parameters_$i"

    if [[ ! -f "$PARAM_FILE" ]]; then
        echo "⚠️  Skipping missing $PARAM_FILE"
        continue
    fi

#    echo "🔥 [$i/$NUM_SAMPLES] Running with $PARAM_FILE..."

    cp "$PARAM_FILE" final_parameters

    # Run Bertini silently
    bertini "$INPUT_FILE" "$START_FILE" > /dev/null 2>&1

    # Get real solution count
    if [[ -f real_finite_solutions ]]; then
        num_real=$(head -c 2 real_finite_solutions | tr -dc '0-9')
    else
        num_real="ERROR"
    fi

    # Call Python tail analysis
    if [[ -f nonsingular_solutions ]]; then
        tail_output=$(python3 "$PYTHON_SCRIPT" nonsingular_solutions)
        real2=$(echo "$tail_output" | grep "Two Real count" | awk -F'Two Real count: ' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
        conjx4=$(echo "$tail_output" | grep "Complex Conj count" | awk -F'Complex Conj count: ' '{print $2}' | tr -d ' ')
    else
        real2="?"
        conjx4="?"
    fi

    # Write result
    echo "final_parameters_$i : $num_real real | TwoReal: $real2 | ComplexConj: $conjx4" >> "$OUTPUT_FILE"
#    echo "✅ Saved: final_parameters_$i"
done

echo "✅ All $NUM_SAMPLES complete. Results in $OUTPUT_FILE"
