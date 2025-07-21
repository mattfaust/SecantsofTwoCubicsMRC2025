#!/bin/bash

OUTFILE="triple_counts.txt"
> "$OUTFILE"

for a in {0..10}; do
  for b in {0..10}; do
    for c in {0..10}; do
      sum=$((a + b + c))
      if [ "$sum" -le 10 ]; then
        count=$(grep -h "${a} real | TwoReal: ${b} | ComplexConj: ${c}" ./*/results.txt 2>/dev/null | wc -l)
        echo "($a, $b, $c) : $count" >> "$OUTFILE"
      fi
    done
  done
done

echo "✅ Written to $OUTFILE"
