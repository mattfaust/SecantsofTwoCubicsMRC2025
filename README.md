# Common Real Secants of a Pair of Real Twisted Cubic Curves

This repository accompanies the paper [https://arxiv.org/abs/2603.25003](https://arxiv.org/abs/2603.25003). 

It provides: 

1. Explicit parameter examples of different configurations of common real secant lines to a pair of real twisted cubic curves. The solutions were certified using [alphaCertified](https://franksottile.github.io/research/stories/alphaCertified/index.html).
2. Data verifying that the monodromy group of the ten secant lines is the full symmetric group, certified using [CertifiedHomotopyTracking.jl](https://github.com/klee669/CertifiedHomotopyTracking.jl).

Below is the input file used to perform a parameter homotopy in Bertini. Observe we use a `PARAMETERHOMOTOPY: 2` as in the [Bertini user guide](https://bertini.nd.edu/BertiniUsersManual.pdf) to search parameter space.
```
CONFIG
condnumthreshold:1e250;
TRACKTYPE: 0;
PARAMETERHOMOTOPY: 2;
END;

INPUT

variable_group t1, t2, s1, s2;

function f1, f2, f3, f4;

constant  m11,m12,m13,m14,
          m21,m22,m23,m24,
          m31,m32,m33,m34,
          m41,m42,m43,m44;

f1 = m31 + m32*s1 + m33*s1^2 + m34*s1^3 - (t1 + t2)*(m21 + m22*s1 + m23*s1^2 + m24*s1^3) + t1*t2*(m11 + m12*s1 + m13*s1^2 + m14*s1^3);

f2 = m31 + m32*s2 + m33*s2^2 + m34*s2^3 - (t1 + t2)*(m21 + m22*s2 + m23*s2^2 + m24*s2^3) + t1*t2*(m11 + m12*s2 + m13*s2^2 + m14*s2^3);

f3 = m41 + m42*s1 + m43*s1^2 + m44*s1^3 - (t1^2 + t1*t2 + t2^2)*(m21 + m22*s1 + m23*s1^2 + m24*s1^3) + t1*t2*(t1 + t2)*(m11 + m12*s1 + m13*s1^2 + m14*s1^3);

f4 = m41 + m42*s2 + m43*s2^2 + m44*s2^3 - (t1^2 + t1*t2 + t2^2)*(m21 + m22*s2 + m23*s2^2 + m24*s2^3) + t1*t2*(t1 + t2)*(m11 + m12*s2 + m13*s2^2 + m14*s2^3);

END;
```

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
