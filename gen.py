import numpy as np
import os
import sys

def sample_point_in_ball(center, radius):
    """
    Samples a single point uniformly inside a 12D ball centered at 'center' with given 'radius'.
    """
    dim = len(center)
    # Use normalized Gaussian direction scaled by random radius^1/d
    direction = np.random.normal(size=dim)
    direction /= np.linalg.norm(direction)
    scale = radius * np.random.random() ** (1.0 / dim)
    return center + scale * direction

def write_final_parameters(filename, point):
    """
    Writes the given 12D real point to a file in Bertini final_parameters format.
    """
    with open(filename, 'w') as f:
        f.write("12\n")
        for val in point:
            f.write(f"{val} 0\n")

def main(center_file, radius, num_samples):
    with open(center_file) as f:
        center = np.array([float(x) for x in f.read().split()])
    assert len(center) == 12, "Center must be 12D"

    os.makedirs("parameter_samples", exist_ok=True)

    for i in range(1, num_samples + 1):
        point = sample_point_in_ball(center, radius)
        filename = f"parameter_samples/final_parameters_{i}"
        write_final_parameters(filename, point)
        print(f"Generated {filename}")

    print(f"✅ Done. {num_samples} files saved to parameter_samples/")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python generate_parameters.py center.txt radius num_samples")
        sys.exit(1)
    center_path = sys.argv[1]
    radius = float(sys.argv[2])
    num = int(sys.argv[3])
    main(center_path, radius, num)
