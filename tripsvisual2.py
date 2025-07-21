import sys
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import ast

def read_triples(filename):
    triples = []
    with open(filename) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            try:
                triple = ast.literal_eval(line)
                if isinstance(triple, tuple) and len(triple) == 3:
                    triples.append(tuple(map(int, triple)))
            except Exception:
                print(f"⚠️ Skipping invalid line: {line}")
    return triples

def plot_triples(triples):
    xs, ys, zs = zip(*triples)

    fig = plt.figure()
    ax = fig.add_subplot(111, projection='3d')
    ax.scatter(xs, ys, zs, c='blue', marker='o', alpha=0.7)

    ax.set_xlabel('Real Solutions (a)')
    ax.set_ylabel('TwoReal (b)')
    ax.set_zlabel('ComplexConj (c)')
    ax.set_title('Observed Triple Distribution (a, b, c)')

    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python plot_triples.py triples.txt")
        sys.exit(1)

    triples = read_triples(sys.argv[1])
    if not triples:
        print("❌ No valid triples found.")
    else:
        print(f"✅ Loaded {len(triples)} triples. Plotting...")
        plot_triples(triples)
