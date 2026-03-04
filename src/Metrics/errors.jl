"""
    calculate_error_metrics(frontier_set::Matrix{F}, reference_set::Matrix{F}) where F <: Number

Computes error metrics between `frontier_set` and `reference`:
- ME: Mean Return Error;
- VE: Variance Return Error;
- MPE: Mean Percentage Error;

For all these metrics, smaller values indicate better performance.
"""
function calculate_error_metrics(frontier_set::Matrix{F}, reference_set::Matrix{F}) where F <: Number
    @warn("Maybe with bugs")
    @assert size(frontier_set, 1) == size(reference_set, 1) "Number of objectives do not match. Each line must represent an objective."

    m, n_f = size(frontier_set)
    n_r = size(reference_set, 2)

    mre_terms = Float64[]
    vre_terms = Float64[]
    mpe_terms = Float64[]

    for i in 1:n_f
        fsol = frontier_set[:, i]
        dists = [norm(fsol .- reference_set[:, j]) for j in 1:n_r]
        j_best = argmin(dists)
        rsol = reference_set[:, j_best]

        for k in 1:m
            vs = fsol[k]
            rs = rsol[k]

            mre = 100 * abs(rs - vs) / (abs(rs) > 1e-12 ? abs(rs) : abs(rs - vs) + 1e-12)
            vre = 100 * abs(vs - rs) / (abs(rs) > 1e-12 ? abs(rs) : abs(rs - vs) + 1e-12)

            psi  = 100 * abs(rs - vs) / (abs(vs) > 1e-12 ? abs(vs) : abs(rs - vs) + 1e-12)
            beta = 100 * abs(sqrt(abs(rs)) - sqrt(abs(vs))) / (sqrt(abs(vs)) > 1e-12 ? sqrt(abs(vs)) : sqrt(abs(rs - vs)) + 1e-12)
            mpe = min(beta, psi)

            push!(mre_terms, mre)
            push!(vre_terms, vre)
            push!(mpe_terms, mpe)
        end
    end

    return mean(mre_terms), mean(vre_terms), mean(mpe_terms)
end
