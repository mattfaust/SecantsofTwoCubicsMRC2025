import sys

def process_file(input_filename):
    try:
        with open(input_filename, 'r') as infile:
            lines = infile.readlines()[1:]  # Skip the first line

        # Extract first column from each line
        numbers = [line.strip().split()[0] for line in lines if line.strip()]

        # Print space-separated numbers
        print(' '.join(numbers))

    except FileNotFoundError:
        print(f"❌ File not found: {input_filename}")
    except Exception as e:
        print(f"❌ An error occurred: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python extract_column.py <input_file>")
    else:
        process_file(sys.argv[1])
