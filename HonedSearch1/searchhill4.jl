#!/usr/bin/env julia
using Random, LinearAlgebra
using HomotopyContinuation


to = TrackerOptions(
  automatic_differentiation = 5,          # up to 3rd‐order AD for robustness
  max_steps               = 500000,       # more total steps
  max_step_size           = 0.2,          # larger allowed predictor steps
  max_initial_step_size   = 0.2,          # same for the very first step
  min_step_size           = 1e-140,        # allow very tiny corrections
  extended_precision      = true,         # keep using mixed precision
  terminate_cond          = 1e12,         # only kill if truly ill‐conditioned
  parameters              = CONSERVATIVE_TRACKER_PARAMETERS
)

eo = EndgameOptions(
  # switch on both Cauchy & Puiseux endgames
  at_infinity_check    = true,
  endgame_start        = 0.1,    # start endgame at t ≤ 0.1
  only_nonsingular     = false,
  zero_is_at_infinity  = false,

  # control work‐budget & series complexity
  max_endgame_steps    = 2000,
  max_winding_number   = 6,

  # when to trigger endgame by condition‐number growth
  min_cond             = 1e6,
  min_cond_growth      = 1e4,

  # detection of diverging coordinates
  min_coord_growth     = 100,

  # only treat as singular‐endpoint if accuracy is good enough
  singular_min_accuracy = 1e-6,

  # valuation thresholds
  val_at_infinity_tol  = 1e-3,
  val_finite_tol       = 1e-3,

  # singularity detection cutoffs
  sing_cond            = 1e14,
  sing_accuracy        = 1e-12,

  # matrix‐scaling & endpoint polish
  scaling_threshold    = -30.0,
  refine_steps         = 3
)

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
               isapprox(s[5], conj(s[6]), atol=tol) && !is_near_real(s[1]),
          sols) 
end


is_near_real(z::ComplexF64) = abs(imag(z)) < tol


"""
 Sum of distances |z1 - conj(z2)| + |z5 - conj(z6)| over all solutions.
 Smaller ⇒ non‑conj‑pairs are “closer” to conjugate.
"""
function total_residual(sols)
    best = minimum(
    norm(s[1] - conj(s[2])) + norm(s[5] - conj(s[6]))
    for s in sols
    if any(!is_near_real, (s[1] + s[2], s[5] + s[6]))   # filter!
    init = 1000
)
end




"""
  count_real_pairs(sols)

Returns the number of solutions where both (z1,z2) and (z5,z6) are real pairs.
"""
function count_real_pairs(sols)
    count(s -> is_near_real(s[1]) && is_near_real(s[2]) &&
               is_near_real(s[5]) && is_near_real(s[6]),
          sols)
end


"""
  count_mixed_pairs(sols)
Returns the number of solutions where exactly one pair is real and the other is a non-real conj pair.
"""
function count_mixed_pairs(sols)
    count(s -> (
        # real pair on (z1,z2) and conj pair on (z5,z6)
        (is_near_real(s[1]) && is_near_real(s[2]) && isapprox(s[5], conj(s[6]), atol=tol) && !is_near_real(s[5])) ||
        # or conj pair on (z1,z2) and real pair on (z5,z6)
        (isapprox(s[1], conj(s[2]), atol=tol) && !is_near_real(s[1]) && is_near_real(s[5]) && is_near_real(s[6]))
    ), sols)
end




function append_params(path::String, p_vec::Vector{Float64})
    open(path, "a") do io
        println(io, join(p_vec, ","))  # CSV line
    end
end

# ---------------------------------------------------
# 5) Hill‑climb loop
# ---------------------------------------------------
target_m   = 9             # goal: 10 conjugate‑pairs
radius     = 0.1
max_iter   = 5000000

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

    result = solve(sys, sol_prev; start_parameters=p0_vec,target_parameters=p_new_vec, tracker_options=to, endgame_options=eo)
#,show_progress = false)

#    result = solve(sys, sol_prev; start_parameters=p0_vec,target_parameters=p_new_vec)
#,show_progress = false)

    sols = solutions(result)

    if length(sols) != 10
#        @warn "Iter $iter: found $(length(sols)) sols, skipping"
#	print(failed(result))
    #c = count_conj(sols)
    #r = total_residual(sols)
    #r_real  = count_real_pairs(sols)
    #r_mixed = count_mixed_pairs(sols)
    #cr = c + r_mixed
#	if (cr > best_c)
#	    println("Iter $iter → conj_count=$c, real_pairs=$r_real, mixed_pairs=$r_mixed, residual=$(round(r, digits=20))")
 #       end
        continue
    end


    # evaluate metrics
    c = count_conj(sols)
    r = total_residual(sols)
    r_real  = count_real_pairs(sols)
    r_mixed = count_mixed_pairs(sols)
    println("Iter $iter → conj_count=$c, real_pairs=$r_real, mixed_pairs=$r_mixed, residual=$(round(r, digits=20))")
    cr = c+r_mixed


    # hill‑climb acceptance:
    if (cr > best_c) || (cr >= best_c && r < best_r)
        println("  ↳ accepted (was count=$best_c, resid=$(round(best_r,digits=20)))")
        global best_c    = cr
        global best_r = r
        global sol_prev      = sols
        global p0_vec    = p_new_vec
        global p_prev        = p_new
	append_params("accepted_parameters.csv", p0_vec)
    else
        println("  ↳ rejected")
    end

    if best_c ≥ target_m
        println("\n🎉 Goal reached at iteration $iter !")
        println("Final p = ", round.(p0_vec; digits=40))
        break
    end
end
