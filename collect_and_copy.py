#!/usr/bin/env python3
import os
import re
import shutil
import sys
from collections import Counter

def extract_triple(line):
    """
    Given a line like:
      final_parameters_585186 : 5 real | TwoReal: 1 | ComplexConj: 1
    returns the triple (5, 1, 1) or None if it doesn't match.
    """
    real_match  = re.search(r":\s*(\d+)\s+real",     line)
    real2_match = re.search(r"TwoReal:\s*(\d+)",     line)
    conj_match  = re.search(r"ComplexConj:\s*(\d+)",  line)

    if real_match and real2_match and conj_match:
        return (int(real_match.group(1)),
                int(real2_match.group(1)),
                int(conj_match.group(1)))
    return None

def extract_id(line):
    """
    From the same line, pull out the numeric ID after 'final_parameters_'.
    E.g. 'final_parameters_585186' → '585186'
    """
    m = re.match(r"^final_parameters_(\d+)", line)
    return m.group(1) if m else None

def collect_triples(file_path):
    """
    Parse results.txt, returning:
      - counts: Counter mapping each triple → its frequency
      - ids:    dict triple → [list of file‑IDs where it occurred]
    """
    counts = Counter()
    ids = {}
    with open(file_path, 'r') as f:
        for line in f:
            if not line.startswith("final_parameters_"):
                continue
            t = extract_triple(line)
            fid = extract_id(line)
            if t and fid:
                counts[t] += 1
                ids.setdefault(t, []).append(fid)
    return counts, ids

def main(root_dir):
    seen_file = os.path.join(root_dir, 'seen2.txt')
    exdir     = os.path.join(root_dir, 'exParameters')
    os.makedirs(exdir, exist_ok=True)

    # load already‑seen triples
    seen = set()
    if os.path.exists(seen_file):
        with open(seen_file) as f:
            for ln in f:
                s = ln.strip()
                if s:
                    seen.add(s)

    # we'll append new triples at the end
    new_triples = []

    for dirpath, dirnames, filenames in os.walk(root_dir):
        if 'results.txt' not in filenames:
            continue

        results_path = os.path.join(dirpath, 'results.txt')
        counts, ids_by_triple = collect_triples(results_path)

        for triple, freq in sorted(counts.items(), key=lambda x: (-x[1], x[0])):
            triple_str = str(triple)
            if triple_str in seen:
                continue

            # first time we've seen this triple
            seen.add(triple_str)
            new_triples.append(triple)

            # pick the first file‑ID for this triple
            fid = ids_by_triple[triple][0]
            src = os.path.join(dirpath, 'parameter_samples',
                               f'final_parameters_{fid}')
            if not os.path.isfile(src):
                print(f"⚠️  Warning: expected file not found: {src}", file=sys.stderr)
                continue

            a, b, c = triple
            dest_name = f'parameter{a}{b}{c}'
            dest = os.path.join(exdir, dest_name)
            shutil.copy2(src, dest)
            print(f"Copied {src} → {dest}")

    # append all new triples to seen2.txt
    if new_triples:
        with open(seen_file, 'a') as f:
            for t in new_triples:
                f.write(str(t) + "\n")
        print(f"\nAppended {len(new_triples)} new triple(s) to seen2.txt")
    else:
        print("No new triples found.")

if __name__ == '__main__':
    # Usage: python collect_and_copy.py [root_directory]
    root = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
    main(root)
