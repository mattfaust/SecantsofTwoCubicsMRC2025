#!/usr/bin/env julia
using Random, LinearAlgebra
using HomotopyContinuation

# ----------------------------------------
# 1. Declare 6 complex variables and 12 parameters
# ----------------------------------------
@polyvar a b r1 r2 t1 t2
@polyvar v1 v2 v3 m1 m2 m3 m4 m5 m6 m7 m8 m9

# ----------------------------------------
# 2. Define your system F(z,p)=0
#    — replace these with your actual polynomials
# ----------------------------------------
f1 = r1*a+(1-r1)*b - (v1 +m1*t1+m2*t1^2+m3*t1^3);
f2 = r1*a^2+(1-r1)*b^2- (v2 +m4*t1+m5*t1^2+m6*t1^3);
f3 = r1*a^3+(1-r1)*b^3-(v3 +m7*t1+m8*t1^2+m9*t1^3);
f4 = r2*a+(1-r2)*b - (v1 +m1*t2+m2*t2^2+m3*t2^3);
f5 = r2*a^2+(1-r2)*b^2-(v2 +m4*t2+m5*t2^2+m6*t2^3);
f6 = r2*a^3+(1-r2)*b^3-(v3 +m7*t2+m8*t2^2+m9*t2^3)
F  = [f1,f2,f3,f4,f5,f6]

sys = System(
  F,
  variables  = [a,b,r1,r2,t1,t2],
  parameters = [v1,v2,v3,m1,m2,m3,m4,m5,m6,m7,m8,m9]
)



# ----------------------------------------
# 3. Function to read in your 10 solutions
# ----------------------------------------
function load_solutions(path)
    lines = readlines(path)
    N = parse(Int, strip(lines[1]))             # first line: "10"
    sol = Vector{Vector{ComplexF64}}(undef, N)
    idx = 2; i = 1
    while i ≤ N
        # skip blank lines
        if isempty(strip(lines[idx]))
            idx += 1; continue
        end
        vec = ComplexF64[]
        for _ in 1:6
            parts = split(strip(lines[idx]))
            re, im = parse(Float64, parts[1]), parse(Float64, parts[2])
            push!(vec, complex(re,im))
            idx += 1
        end
        sol[i] = vec
        i += 1
    end
    return sol
end

#println("Working directory: ", pwd())
#println("Files here: ", readdir())
#@assert isfile("nonsingular_solutions") "ERROR: File not found!"


prevSolnbby = load_solutions("nonsingular_solutions")

# ----------------------------------------
# 3. Initial solve at seed parameters p⁽⁰⁾
# ----------------------------------------
p0_vec = [0.18618657992246557, 1.0708403923495844, 0.10325619205528191, 7.164509434808381, 0.808048339635927, 8.562191790780727, 1.6013191365536088, 14.721850583330937, 5.268090443236682, 0.5012381267755297, 2.6460958485858512, 8.620126073982671]
p0 = Dict( zip(sys.parameters, p0_vec) )

# ----------------------------------------
# 4. Homotopy loop: perturb p, track those 10, test conjugacy
# ----------------------------------------
target_m = 10     # how many conjugate‐pair solutions you want
tol      = 1e-8   # numerical tolerance for conjugacy
radius   = 0.02    # step‐size in the parameter ball
max_iter = 1

for iter in 1:max_iter
    # 4a) random perturbation in the 12‐dim ball
    Δ = radius * (2*rand(12) .- 1)
    p_new_vec = p0_vec .+ Δ
    p_new = Dict( zip(sys.parameters, p_new_vec) )

    # 4b) parameter homotopy tracking only those 10
    res = solve(
      sys;
      start_solutions = prevSolnbby,
      parameters      = p_new,
      show_progress   = false
    )
    sols = res.solutions

    # 4c) count how many of your 10 satisfy the two conjugate‐pair checks
    good = count(s -> isapprox(s[a], conj(s[b]), atol=tol) &&
                     isapprox(s[t1], conj(s[t2]), atol=tol),
                 sols)

    println("Iter $iter — found $good / 10 conjugate‐pair solutions")

    if good ≥ target_m
        println("\n✅ Success at iter $iter: parameter = ",
                round.(p_new_vec; digits=20))
        break
    end

    # 4d) prepare for next iteration
    global prevSolnbby = sols
    # (optionally adapt `radius` here, e.g. `radius *= 0.9`)
end
