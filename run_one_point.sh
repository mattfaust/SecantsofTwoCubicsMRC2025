#!/usr/bin/env bash
set -euo pipefail

require_command() {
  local cmd="$1"
  local msg="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: $msg"
    exit 1
  fi
}

require_command python3 "python3 not found in PATH."
require_command bertini "Bertini not found in PATH."

if [[ $# -lt 1 ]]; then
  echo "Usage:"
  echo "  ./run_one_point.sh /path/to/parameter_file.txt [tag]"
  exit 1
fi

PARAM_FILE="$1"
TAG="$(basename "$PARAM_FILE" .txt)"

if [[ $# -ge 2 ]]; then
  TAG="$2"
fi

if [[ ! -f "$PARAM_FILE" ]]; then
  echo "ERROR: parameter file not found: $PARAM_FILE"
  exit 1
fi

PARAM_FILE="$(cd "$(dirname "$PARAM_FILE")" && pwd)/$(basename "$PARAM_FILE")"

START_DIR="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BASE="$START_DIR/run_one_${STAMP}_${TAG}"
mkdir -p "$BASE"
SUMMARY="$BASE/summary_${STAMP}_${TAG}.txt"
: > "$SUMMARY"

D="$BASE/$TAG"
mkdir -p "$D"
cd "$D"

cp "$PARAM_FILE" parameter_point.txt

cat > classify_4x4.py <<'PY'
#!/usr/bin/env python3
import argparse
import math
import sys
from typing import List, Tuple, Dict, Set

Complex4 = Tuple[complex, complex, complex, complex]
Inv4 = Tuple[complex, complex, complex, complex]
LABELS = ["TOTALLY", "PARTIAL", "MINIMAL", "NONREAL", "ANOMALY"]


def parse_re_im_lines(path: str) -> List[Complex4]:
    vals: List[complex] = []
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split()
            if len(parts) < 2:
                continue
            try:
                re = float(parts[0])
                im = float(parts[1])
            except Exception:
                continue
            vals.append(complex(re, im))

    if len(vals) % 4 != 0:
        raise ValueError(f"{path}: expected total #complex values multiple of 4, got {len(vals)}.")

    sols: List[Complex4] = []
    for i in range(0, len(vals), 4):
        sols.append((vals[i], vals[i + 1], vals[i + 2], vals[i + 3]))
    return sols


def is_real(z: complex, tol: float) -> bool:
    return abs(z.imag) <= tol


def is_conj_pair(z: complex, w: complex, tol: float) -> bool:
    return abs(z - w.conjugate()) <= tol


def pair_type(a: complex, b: complex, tol: float) -> str:
    if is_real(a, tol) and is_real(b, tol):
        return "REALPAIR"
    if is_conj_pair(a, b, tol) or is_conj_pair(b, a, tol):
        return "CONJPAIR"
    return "OTHER"


def classify(sol: Complex4, tol: float) -> str:
    t1, t2, s1, s2 = sol
    ttype = pair_type(t1, t2, tol)
    if ttype == "OTHER":
        return "NONREAL"
    stype = pair_type(s1, s2, tol)
    if ttype == "REALPAIR" and stype == "REALPAIR":
        return "TOTALLY"
    if (ttype == "REALPAIR" and stype == "CONJPAIR") or (ttype == "CONJPAIR" and stype == "REALPAIR"):
        return "PARTIAL"
    if ttype == "CONJPAIR" and stype == "CONJPAIR":
        return "MINIMAL"
    return "ANOMALY"


def max_abs(sol: Complex4) -> float:
    return max(abs(z) for z in sol)


def invariants(sol: Complex4) -> Inv4:
    t1, t2, s1, s2 = sol
    return (t1 + t2, t1 * t2, s1 + s2, s1 * s2)


def inv_dist(a: Inv4, b: Inv4) -> float:
    d2 = 0.0
    for x, y in zip(a, b):
        d2 += (x.real - y.real) ** 2 + (x.imag - y.imag) ** 2
    return math.sqrt(d2)


def inv_mean(invs: List[Inv4], idxs: List[int]) -> Inv4:
    sr = [0.0] * 4
    si = [0.0] * 4
    m = float(len(idxs))
    for i in idxs:
        v = invs[i]
        for k in range(4):
            sr[k] += v[k].real
            si[k] += v[k].imag
    return (
        complex(sr[0] / m, si[0] / m),
        complex(sr[1] / m, si[1] / m),
        complex(sr[2] / m, si[2] / m),
        complex(sr[3] / m, si[3] / m),
    )


class DSU:
    def __init__(self, n: int):
        self.p = list(range(n))
        self.r = [0] * n

    def find(self, a: int) -> int:
        while self.p[a] != a:
            self.p[a] = self.p[self.p[a]]
            a = self.p[a]
        return a

    def union(self, a: int, b: int) -> None:
        ra, rb = self.find(a), self.find(b)
        if ra == rb:
            return
        if self.r[ra] < self.r[rb]:
            ra, rb = rb, ra
        self.p[rb] = ra
        if self.r[ra] == self.r[rb]:
            self.r[ra] += 1


def component_labels(labs: List[str], idxs: List[int]) -> Set[str]:
    return {labs[i] for i in idxs}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("solutions_file")
    ap.add_argument("--tol", type=float, default=1e-13)
    ap.add_argument("--orbits", action="store_true")
    ap.add_argument("--filter-collisions", action="store_true")
    ap.add_argument("--max-abs", type=float, default=None)
    ap.add_argument("--orbit-mult-min", type=int, default=1)
    ap.add_argument("--orbit-eps", type=float, default=1e-7)
    ap.add_argument("--orbit-merge-eps", type=float, default=None)
    ap.add_argument("--debug-dropped", action="store_true")
    ap.add_argument("--print-mult-hist", action="store_true")
    args = ap.parse_args()

    sols = parse_re_im_lines(args.solutions_file)
    kept: List[Complex4] = []
    labs: List[str] = []
    dropped = {"collision": 0, "max_abs": 0, "nonfinite": 0}

    for sol in sols:
        t1, t2, s1, s2 = sol
        if not all(math.isfinite(z.real) and math.isfinite(z.imag) for z in sol):
            dropped["nonfinite"] += 1
            continue
        if args.filter_collisions and (abs(t1 - t2) <= args.tol or abs(s1 - s2) <= args.tol):
            dropped["collision"] += 1
            continue
        if args.max_abs is not None and max_abs(sol) > args.max_abs:
            dropped["max_abs"] += 1
            continue
        kept.append(sol)
        labs.append(classify(sol, args.tol))

    counts_by_solution: Dict[str, int] = {k: 0 for k in LABELS}
    for lab in labs:
        counts_by_solution[lab] += 1

    print(f"File: {args.solutions_file}")
    print(f"tol = {args.tol:g}")
    print(f"solutions_read = {len(sols)}")
    print(f"solutions_kept = {len(kept)}")

    print("\nCounts by solution:")
    for k in LABELS:
        print(f"  {k:8s} {counts_by_solution[k]}")

    invs = [invariants(sol) for sol in kept]

    if not args.orbits:
        if counts_by_solution["ANOMALY"] > 0:
            sys.exit(2)
        return

    n = len(kept)
    dsu = DSU(n)
    for i in range(n):
        for j in range(i + 1, n):
            if inv_dist(invs[i], invs[j]) <= args.orbit_eps:
                dsu.union(i, j)

    comps: Dict[int, List[int]] = {}
    for i in range(n):
        r = dsu.find(i)
        comps.setdefault(r, []).append(i)

    if args.orbit_merge_eps is not None:
        comp_idxs = list(comps.values())
        changed = True
        while changed:
            changed = False
            m = len(comp_idxs)
            centroids = [inv_mean(invs, idxs) for idxs in comp_idxs]
            label_sets = [component_labels(labs, idxs) for idxs in comp_idxs]
            merged = [False] * m
            new_comp_idxs: List[List[int]] = []

            for i in range(m):
                if merged[i]:
                    continue
                cur = comp_idxs[i][:]
                cur_labels = label_sets[i]
                cur_cent = centroids[i]
                if len(cur_labels) != 1:
                    new_comp_idxs.append(cur)
                    continue
                for j in range(i + 1, m):
                    if merged[j]:
                        continue
                    if len(label_sets[j]) != 1:
                        continue
                    if next(iter(label_sets[j])) != next(iter(cur_labels)):
                        continue
                    if inv_dist(cur_cent, centroids[j]) <= args.orbit_merge_eps:
                        cur.extend(comp_idxs[j])
                        merged[j] = True
                        changed = True
                        cur_cent = inv_mean(invs, cur)
                new_comp_idxs.append(cur)
            comp_idxs = new_comp_idxs
        comps = {k: v for k, v in enumerate(comp_idxs)}

    raw_mult_hist: Dict[int, int] = {}
    orbit_recs: List[Dict[str, object]] = []
    for idxs in comps.values():
        mult = len(idxs)
        raw_mult_hist[mult] = raw_mult_hist.get(mult, 0) + 1
        labset = component_labels(labs, idxs)
        lab = next(iter(labset)) if len(labset) == 1 else "ANOMALY"
        rep = kept[idxs[0]]
        orbit_recs.append({"label": lab, "rep": rep, "mult": mult})

    if args.print_mult_hist:
        print("\nRaw orbit multiplicity histogram:")
        for m in sorted(raw_mult_hist):
            print(f"  mult={m}: {raw_mult_hist[m]}")

    filtered = [rec for rec in orbit_recs if int(rec["mult"]) >= args.orbit_mult_min]
    orbit_counts: Dict[str, int] = {k: 0 for k in LABELS}
    for rec in filtered:
        orbit_counts[str(rec["label"])] += 1

    print(f"\norbits(lines) = {len(filtered)}  (raw orbits = {len(orbit_recs)})")
    print(f"orbit_mult_min = {args.orbit_mult_min}")
    print(f"orbit_eps = {args.orbit_eps:g}")
    if args.orbit_merge_eps is not None:
        print(f"orbit_merge_eps = {args.orbit_merge_eps:g}")

    print("Counts by orbit/line:")
    for k in LABELS:
        print(f"  {k:8s} {orbit_counts[k]}")

    print(
        "TRIPLE "
        f"{orbit_counts['TOTALLY']} "
        f"{orbit_counts['PARTIAL']} "
        f"{orbit_counts['MINIMAL']} "
        f"{orbit_counts['NONREAL']} "
        f"{orbit_counts['ANOMALY']}"
    )

    out_path = args.solutions_file + "_orbit_reps.txt"
    with open(out_path, "w") as f:
        f.write("# label  mult   t1(re) t1(im)  t2(re) t2(im)  s1(re) s1(im)  s2(re) s2(im)\n")
        for rec in filtered:
            lab = str(rec["label"])
            mult = int(rec["mult"])
            t1, t2, s1, s2 = rec["rep"]  # type: ignore[misc]
            f.write(
                f"{lab:8s} {mult:4d}  "
                f"{t1.real:.16e} {t1.imag:.16e}  "
                f"{t2.real:.16e} {t2.imag:.16e}  "
                f"{s1.real:.16e} {s1.imag:.16e}  "
                f"{s2.real:.16e} {s2.imag:.16e}\n"
            )

    print(f"\nWrote orbit representatives to: {out_path}")
    if orbit_counts["ANOMALY"] > 0:
        sys.exit(2)


if __name__ == "__main__":
    main()
PY

chmod +x classify_4x4.py

parsed=$(
python3 - "$PARAM_FILE" <<'PY'
import sys
path = sys.argv[1]
with open(path) as f:
    raw = [ln.strip() for ln in f if ln.strip() and not ln.strip().startswith("#")]

vals = []
if len(raw) == 17 and raw[0] == "16":
    rows = raw[1:]
elif len(raw) == 16:
    rows = raw
else:
    raise SystemExit(
        f"ERROR: unsupported parameter-file format in {path}. "
        "Expected either 17 nonempty lines starting with 16, or exactly 16 nonempty lines."
    )

for ln in rows:
    vals.append(ln.split()[-1])

if len(vals) != 16:
    raise SystemExit(f"ERROR: expected 16 parameter values, got {len(vals)}")

for v in vals:
    print(v)
PY
)

RAW_LINES=()
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  RAW_LINES+=("$line")
done <<EOF_PARSE
$parsed
EOF_PARSE

if [[ ${#RAW_LINES[@]} -ne 16 ]]; then
  echo "ERROR: expected 16 parameter values after parsing, got ${#RAW_LINES[@]}"
  exit 1
fi

a10="${RAW_LINES[0]}"  ; a11="${RAW_LINES[1]}"  ; a12="${RAW_LINES[2]}"  ; a13="${RAW_LINES[3]}"
a20="${RAW_LINES[4]}"  ; a21="${RAW_LINES[5]}"  ; a22="${RAW_LINES[6]}"  ; a23="${RAW_LINES[7]}"
a30="${RAW_LINES[8]}"  ; a31="${RAW_LINES[9]}"  ; a32="${RAW_LINES[10]}" ; a33="${RAW_LINES[11]}"
a40="${RAW_LINES[12]}" ; a41="${RAW_LINES[13]}" ; a42="${RAW_LINES[14]}" ; a43="${RAW_LINES[15]}"

echo "==============================" | tee -a "$SUMMARY"
echo "Running $TAG" | tee -a "$SUMMARY"
echo "Parameter file: $PARAM_FILE" | tee -a "$SUMMARY"
echo "Run directory: $D" | tee -a "$SUMMARY"
echo "==============================" | tee -a "$SUMMARY"

cat > input <<EOF_INPUT
CONFIG
condnumthreshold:1e250;
TRACKTYPE: 0;
PARAMETERHOMOTOPY: 0;
END;

INPUT
variable_group t1, t2, s1, s2;
function f1, f2, f3, f4;

f1 =
 ($a30 + $a31*s1 + $a32*s1^2 + $a33*s1^3)
 - (t1 + t2)*($a20 + $a21*s1 + $a22*s1^2 + $a23*s1^3)
 + (t1*t2);

f2 =
 ($a31 + $a32*(s1 + s2) + $a33*(s1^2 + s1*s2 + s2^2))
 - (t1 + t2)*($a21 + $a22*(s1 + s2) + $a23*(s1^2 + s1*s2 + s2^2));

f3 =
 ($a40 + $a41*s1 + $a42*s1^2 + $a43*s1^3)
 - (t1^2 + t1*t2 + t2^2)*($a20 + $a21*s1 + $a22*s1^2 + $a23*s1^3)
 + (t1*t2*(t1 + t2));

f4 =
 ($a41 + $a42*(s1 + s2) + $a43*(s1^2 + s1*s2 + s2^2))
 - (t1^2 + t1*t2 + t2^2)*($a21 + $a22*(s1 + s2) + $a23*(s1^2 + s1*s2 + s2^2));

END;
EOF_INPUT

echo "[1/2] Running Bertini..." | tee -a "$SUMMARY"
bertini input > bertini.log 2>&1

if [[ ! -s nonsingular_solutions ]]; then
  echo "ERROR: Bertini did not produce nonsingular_solutions" | tee -a "$SUMMARY"
  echo "See bertini.log in: $D" | tee -a "$SUMMARY"
  exit 1
fi

echo "[2/2] Classifying Bertini nonsingular_solutions..." | tee -a "$SUMMARY"

python3 classify_4x4.py nonsingular_solutions \
  --orbits \
  --tol 1e-8 \
  --orbit-eps 3e-7 \
  --orbit-mult-min 4 \
  --print-mult-hist \
  > classification.txt 2> classification.err || true

echo | tee -a "$SUMMARY"
echo "===== classification.txt for $TAG =====" | tee -a "$SUMMARY"
cat classification.txt | tee -a "$SUMMARY"
echo | tee -a "$SUMMARY"

if [[ ! -s nonsingular_solutions_orbit_reps.txt ]]; then
  echo "ERROR: classification did not produce nonsingular_solutions_orbit_reps.txt" | tee -a "$SUMMARY"
  echo "See classification.err in: $D" | tee -a "$SUMMARY"
  exit 1
fi

echo "Done." | tee -a "$SUMMARY"
echo "Summary file:"
echo "  $SUMMARY"
echo "Run directory:"
echo "  $BASE"
