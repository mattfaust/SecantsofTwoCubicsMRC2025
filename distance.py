import sys
import math

def read_real_vector(filepath):
    with open(filepath) as f:
        lines = f.readlines()

    if len(lines) < 13:
        raise ValueError(f"File {filepath} is too short to contain 12 parameters.")

    # Skip first line and extract real parts only
    real_parts = []
    for line in lines[1:13]:
        parts = line.strip().split()
        real_parts.append(float(parts[0]))
    
    return real_parts

def euclidean_distance(vec1, vec2):
    return math.sqrt(sum((a - b)**2 for a, b in zip(vec1, vec2)))

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python distance_between_parameters.py file1 file2")
        sys.exit(1)

    file1, file2 = sys.argv[1], sys.argv[2]

    try:
        vec1 = read_real_vector(file1)
        vec2 = read_real_vector(file2)
        distance = euclidean_distance(vec1, vec2)
        print(f"✅ Euclidean distance between '{file1}' and '{file2}': {distance:.8f}")
    except Exception as e:
        print(f"❌ Error: {e}")
