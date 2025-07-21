import sys
import os

THRESHOLD = 0.001  # Tolerance to call an imaginary part zero

def is_real_point(im1, tol=THRESHOLD):
    return abs(im1)< tol
def is_complexConj_point(im1, im2, tol=THRESHOLD):
    return abs(im1 + im2) < tol

def analyze_tail(filename):
    if not os.path.exists(filename):
        print(f"❌ File not found: {filename}")
        return "unknown"

    with open(filename) as f:
        lines = [line.strip() for line in f if line.strip()]

    lines = lines[1:len(lines)]
    realpart = []
    complexpart = []
    for i in lines:
        numlist = i.split(" ")
        realpart.append(float(numlist[0]))
        complexpart.append(float(numlist[1]))

    total_blocks = len(lines) // 6

    real2 = 0
    complexx4 = 0
    for i in range(total_blocks):
        block_start = i * 6

        complex1 = complexpart[block_start]
        complex2 = complexpart[block_start + 1]
        complex3 = complexpart[block_start + 4]
        complex4 = complexpart[block_start + 5]
        
        if is_real_point(complex1) and is_real_point(complex2) and is_real_point(complex3) and is_real_point(complex4):
            continue

        if is_complexConj_point(complex1, complex2) and is_real_point(complex3) and is_real_point(complex4):
                real2 += 1
                continue
        if is_complexConj_point(complex3, complex4) and is_real_point(complex1) and is_real_point(complex2):
                real2 += 1
                continue
        if is_complexConj_point(complex1, complex2) and is_complexConj_point(complex3, complex4):
                complexx4 += 1
#                print(complex1, complex2, complex3, complex4)
#                print(complex1 + complex2)
                continue
        
    print("Two Real count: " + str(real2) + ", Complex Conj count: " + str(complexx4))
    return real2, complexx4


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python analyze_last_four_points.py nonsingular_solutions")
        sys.exit(1)

    real2, complexx4 = analyze_tail(sys.argv[1])
    print(f"✅ Tail classification: Two real count:" + str(real2) + ", Complex conjugate count: " + str(complexx4))

