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
#F  = [f1,f2,f3,f4,f5,f6]

sys = System(
  [f1,f2,f3,f4,f5,f6],
  variables  = [a,b,r1,r2,t1,t2],
  parameters = [v1,v2,v3,m1,m2,m3,m4,m5,m6,m7,m8,m9]
)

#params = [v1,v2,v3,m1,m2,m3,m4,m5,m6,m7,m8,m9]



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


sol_prev = load_solutions("nonsingular_solutions")

# ---------------------------------------------------
# 4) Helper metrics
# ---------------------------------------------------
const tol = 1e-8
function count_conj(sols)
    count(s -> isapprox(s[1], conj(s[2]), atol=tol) &&
               isapprox(s[5], conj(s[6]), atol=tol),
          sols)
end

"""
 Sum of distances |z1 - conj(z2)| + |z5 - conj(z6)| over all solutions.
 Smaller ⇒ non‑conj‑pairs are “closer” to conjugate.
"""
function total_residual(sols)
    sum(norm(s[1] - conj(s[2])) + norm(s[5] - conj(s[6])) for s in sols)
end

# ---------------------------------------------------
# 5) Hill‑climb loop
# ---------------------------------------------------
target_m   = 9             # goal: 10 conjugate‑pairs
radius     = 0.1
max_iter   = 2000000

# your initial parameter vector p0_vec must match the seeds
p0_vec = [0.18618657992246557, 1.0708403923495844, 0.10325619205528191, 7.164509434808381, 0.808048339635927, 8.562191790780727, 1.6013191365536088, 14.721850583330937, 5.268090443236682, 0.5012381267755297, 2.6460958485858512, 8.620126073982671]
p_prev     = Dict(zip(sys.parameters, p0_vec))

#print(typeof(p_prev))

best_c    = count_conj(sol_prev)
best_r = total_residual(sol_prev)

println("Starting count = $best_c, residual = $best_r")

for iter in 1:max_iter
    # propose new p
    Δ         = radius .* (2 .* rand(12) .- 1)
    p_new_vec = p0_vec .+ Δ
    p_new     = Dict(zip(sys.parameters, p_new_vec))
#    print(typeof(p_new))
    # track only your 10 starts via parameter homotopy
    result = solve(sys, sol_prev; start_parameters=p0_vec,target_parameters=p_new_vec)
#,show_progress = false)

    sols = solutions(result)

    # evaluate metrics
    c = count_conj(sols)
    r = total_residual(sols)
    println("Iter $iter → count = $c, residual = $(round(r,digits=20))")

    # hill‑climb acceptance:
    if (c > best_c) || (c == best_c && r < best_r)
        println("  ↳ accepted (was count=$best_c, resid=$(round(best_r,digits=20)))")
        global best_c    = c
        global best_r = r
        global sol_prev      = sols
        global p0_vec    = p_new_vec
        global p_prev        = p_new
    else
        println("  ↳ rejected")
    end

    if best_c ≥ target_m
        println("\n🎉 Goal reached at iteration $iter!")
        println("Final p = ", round.(p_prev_vec; digits=18))
        break
    end
end
