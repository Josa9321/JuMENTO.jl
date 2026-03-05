"""
    Metrics

This module provides functions to compute performance metrics for multi-objective optimization problems. The following metrics are implemented:

- `diversity`: Measures the dispersion of the solution set. Smaller values indicate better performance.
- `error_ratio`: Computes the proportion of solutions in the evaluated set that are not present in the reference set. Smaller values indicate better performance.
- `errors`: Computes a collection of error-based metrics - that is, mean return error, variance return error, mean percentage error - to assess the quality of the solution set. Smaller values for each of these metrics indicate better performance.
- `general_distance`: Calculates the p-norm of euclidean distances from each solution in the evaluated set to its nearest neighbor in the reference set. Smaller values indicate that the evaluated set is closer to the reference set, which is desirable.
- `hypervolume`: Computes the hypervolume of the objective space dominated by the solution set. Larger values indicate better performance.
- `spacing`: Measures the variation in distances between each solution in the evaluated set and its nearest neighbor in the reference set. Smaller values are desirable.

For further details on these metrics, see:

Silva, Y. L. T. V., Herthel, A. B., & Subramanian, A. (2019).
"A multi-objective evolutionary algorithm for a class of mean-variance portfolio selection problems."
Expert Systems with Applications, 133, 225–241.
https://doi.org/10.1016/j.eswa.2019.05.018
"""
module Metrics

using LinearAlgebra, Statistics

export diversity, error_ratio, calculate_error_metrics, general_distance, hypervolume, spacing

include("diversity.jl")
include("error_ratio.jl")
include("errors.jl")
include("general_distance.jl")
include("hypervolume.jl")
include("spacing.jl")

end
