# Common Real Secants of a Pair of Real Twisted Cubic Curves

This repository accompanies the paper [https://arxiv.org/abs/2603.25003](https://arxiv.org/abs/2603.25003). 

It provides: 

1. Explicit parameter examples of different configurations of common real secant lines to a pair of real twisted cubic curves. The solutions were certified using [alphaCertified](https://franksottile.github.io/research/stories/alphaCertified/index.html).
2. Data verifying that the monodromy group of the ten secant lines is the full symmetric group, certified using [CertifiedHomotopyTracking.jl](https://github.com/klee669/CertifiedHomotopyTracking.jl).

## Classification

Let $C_1$ and $C_2$ be real twisted cubic curves in $\mathbb{P}^{3}$, and let $\ell$ a common real secant line to both curves. The intersection of $\ell$ with each curve determines its type:

   1. Totally real: both $C_1\cap \ell$ and $C_2\cap \ell$ consist of two real points,
   
   2. Partially real: one intersection is real and the other is a pair of nonreal complex conjugate points,
   
   3. Minimally real: both intersections consist of nonreal complex conjugate pairs.

## Counting Secant Lines

For a generic pair of real twisted cubics, there are exactly 10 common secant lines. We represent their distribution using a $3$-tuple $(n_t,n_p,n_m)$ where $n_t$, $n_p$, and $n_m$ are the number of totally real, partially real, and minimally real common secant lines, respectively. 

The total number of common real secant lines is $n_{\mathbb{R}}$ $: = n_t+n_p+n_m$, and the number of common nonreal secant lines is $10-n_{\mathbb{R}}$. Since nonreal solutions occur in complex conjugate pairs, $n_{\mathbb{R}}$ must be even, with $n_t,n_p,n_m\in$ {0,1,...,10}.

A 3-tuple $(n_{t},n_{p},n_{m})$ is admissible if $n_{t},n_{p},n_{m} \in$ {0,1,...,10} and $n_{\mathbb{R}}$ is even and at most 10. There are a total of $161$ distinct admissible $3$-tuples $(n_t,n_p,n_m)$. An admissible $3$-tuple $(n_{t},n_{p},n_{m})$ is realizable if there exists real twisted cubic curves $C_{1},C_{2}$ whose $10$ common secant lines yield that distribution.

## Repository Structure

`100000_run` contains the 100000 parameters studied in the paper [https://arxiv.org/abs/2603.25003](https://arxiv.org/abs/2603.25003).

`example_parameters` contains the explicit parameters realizing specific 3-tuples

`Monodromy_computation.txt` contains the certification data for the monodromy group

`local_sampling_guide.txt` is the guide to randomly sample around a given point