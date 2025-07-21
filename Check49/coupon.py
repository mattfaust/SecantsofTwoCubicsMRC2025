from collections import Counter
import re

def extract_triple(line):
    """
    Extracts a (num_real, real2, conjx4) triple from a line like:
    final_parameters_3 : 6 real | TwoReal: 1 | ComplexConj: 2
    """
    real_match = re.search(r":\s*(\d+)\s+real", line)
    real2_match = re.search(r"TwoReal:\s*(\d+)", line)
    conjx4_match = re.search(r"ComplexConj:\s*(\d+)", line)

    if real_match and real2_match and conjx4_match:
        return (
            int(real_match.group(1)),
            int(real2_match.group(1)),
            int(conjx4_match.group(1))
        )
    return None

def count_frequencies(file_path):
    triple_counts = Counter()

    with open(file_path, 'r') as f:
        for line in f:
            if line.startswith("final_parameters"):
                triple = extract_triple(line)
                if triple:
                    triple_counts[triple] += 1

    return triple_counts

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 2:
        print("Usage: python count_triple_frequencies.py results.txt")
        sys.exit(1)

    counts = count_frequencies(sys.argv[1])

    print("🧮 Triple frequencies (num_real, TwoReal, ComplexConj):")
    for triple, count in sorted(counts.items(), key=lambda x: (-x[1], x[0])):
        print(f"{triple} : {count}")
