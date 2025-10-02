<div align="center">
<img src="https://github.com/Josa9321/Jumento.jl/blob/main/Jumento.png" alt="Logo" width="250">
</div>

# **JuMENTO: Multi-Objective Optimization in Julia**

[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Julia](https://img.shields.io/badge/julia-v1.8+-blue.svg)](https://julialang.org/)

JuMENTO is a Julia-based framework for **multi-objective optimization**, implementing two widely used families of methods:

- **AUGMECON** and **AUGMECON 2** (Augmented ε-Constraint Method)
- **NSGA-II** (Non-dominated Sorting Genetic Algorithm II)

It integrates seamlessly with [JuMP](https://jump.dev/) models and provides:

- Exact and metaheuristic optimization methods
- Metrics for Pareto front quality assessment
- Tools for saving and plotting results

---

## **Table of Contents**

- [Installation](#installation)
- [How to Use](#how-to-use)
  - [1. Build a Model](#1-build-a-model)
  - [2. Configure User Options for AUGMECON and AUGMECON 2](#2-configure-user-options-for-augmecon-and-augmecon-2)
  - [3. Solve with AUGMECON](#3-solve-with-augmecon)
  - [4. Configure User Options for NSGA-II](#4-configure-user-options-for-nsga-ii)
  - [5. Solve with NSGA-II](#5-solve-with-nsga-ii)
  - [6. Plot Results](#6-plot-results)
  - [7. Save Results](#7-save-results)
- [Metrics for Evaluation](#-metrics-for-evaluation)
- [Example Problems](#-example-problems)
- [References](#-references)

---

## **Installation**

For installation, you can download directly from github as follows:

```julia
using Pkg
Pkg.add(url="https://github.com/Josa9321/JuMENTO.jl")
```

---

## **How to Use**

### **1. Build a Model**

First, declare a **JuMP** model to use AUGMECON, AUGMECON2, or NSGA-II (see [JuMP Documentation](https://jump.dev/JuMP.jl/stable/)).
Below is an example showing how to build a model for use with JuMENTO:

```julia
using JuMP, JuMENTO, HiGHS

model = Model(HiGHS.Optimizer)

@variable(model, x[1:2] >= 0) 

@constraints model begin
    c1, x[1] <= 20
    c2, x[2] <= 40
    c3, 5*x[1] + 4*x[2] <= 200
end
@objective(model, Max, [x[1],  3*x[1] + 4*x[2]])
```

Note that the objective sense must be specified when using the `@objective` macro. In the JuMENTO package, this sense is applied to the entire objective vector. To set the sense for each objective individually, pass the `objective_sense_set` option when calling `augmecon` (see [section 2](#2-configure-user-options-for-augmecon-and-augmecon-2)).

Alternatively, you can declare the objectives as JuMP variables and assign their values with equality constraints.

```julia
model = Model(HiGHS.Optimizer)

@variables model begin
    x[1:2] >= 0
    objs[1:2]
end

@constraints model begin
    c1, x[1] <= 20
    c2, x[2] <= 40
    c3, 5*x[1] + 4*x[2] <= 200

    objective_1, objs[1] == x[1]
    objective_2, objs[2] == 3*x[1] + 4*x[2]
end
```

---

### **2. Configure User Options for AUGMECON and AUGMECON 2**

When using an AUGMECON-based method, you can control its behavior by passing keyword options to `augmecon`. Some options are required; others are optional. The table below summarizes the available parameters:

| Parameter               | Description                                                           | Default       |
| ----------------------- | --------------------------------------------------------------------- | ------------- |
| `grid_points`         | Number of grid divisions for ε-constraint                            | Required      |
| `nadir`               | Nadir point for normalization                                         | Auto computed |
| `objective_sense_set` | Objective sense for each objective (:Min or :Max)                     | [:Max ...]    |
| `penalty`             | Numeric value that is used by the AUGMECON                            | 1e-3          |
| `bypass`              | Used to know whether or not AUGMECON 2 will be used                   | true          |
| `dominance_eps`       | Tolerance used when determining dominance relations between solutions | 1e-8          |
| `print_level`         | Logging detail (0 or 1)                                               | 0             |

---

### **3. Solve with AUGMECON**

Solve the model above with the `augmecon` function. The call returns the Pareto frontier (a `Vector{SolutionJuMP}`) and a report with method diagnostics.

```julia
frontier, report = augmecon(model, grid_points=10)
```

If the objectives were declared as JuMP variables, call:

```julia
frontier, report = augmecon(model, objs, grid_points=10)
```

---

### **4. Configure User Options for NSGA-II**

To use AUGMECON, the user can provide some additional information that will be taken into account when making a decision. Below are some of the details:

| Parameter          | Description                                   | Default |
| ------------------ | --------------------------------------------- | ------- |
| `pop_size`         | Population size                               | 100     |
| `generations`      | Number of generations                         | 100     |
| `penalty`          | Penalty type for constraint violations        | linear  |
| `mutation_rate`    | Mutation probability                          | 0.05    |
| `crossover_rate`   | Crossover probability                         | 0.9     |
| `default_range`    | Default variable range if no bounds specified | 100.0   |

*NOTE*: The penalty_type determines how constraint violations are penalized. Each type is recommended for different scenarios:

    - linear: Used where the impact of constraint violations is proportional and moderate and when large violations do not need to be heavily punished.

    - quadratic: Used when you want to strongly discourage large violations while tolearting small ones at the start. He forces solutions to become feasible quickly.

    - inverse: Used when small violations should be penalized more heavily than large ones. He preserves diversity and exploration in early generations.

    - adaptive: Used for difficult problems with many constraints, where you want to allow violations in the early stage and gradually enforce feasibility.

*NOTE*: The default_range value is necessary when no upper bounds are established for a variable. Therefore, a float value is used to determine a possible range. It's also important to note that a very large default_range value can cause the number of generations required to reach a viable solution to take a long time.

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

### **5. Solve with NSGA-II**

To use NSGA-II, you need to call it with two objects that will store the results. For options, you need to add a ";" after the model. Below is an example:

```julia
frontier, report = nsga2(model; pop_size=200,generations=200,penalty=:quadratic)
```

---

### **6. Plot results**

If you want to plot the results found, the following function can be called:

```julia
plot_result(frontier, model)
```

Here is an example of how the plot will look:

![Plot_of_results]["images/Plots.png"]

*NOTE*: This function plots both the Pareto frontier and the variables.

---

### **7. Save results**

You may be saving the results of the frontier and the report, with an existing function in JuMENTO, but it is necessary to also pass a location where the files will be downloaded. The function follows:

```julia
save_results_to_file(frontier, report, "User/<username>/Download") # Here the "Download" folder was used as an example
```

---

## **Metrics for Evaluation**

To compare the performance of different algorithms, specific multi-objective metrics are used to assess the quality of the solution sets obtained. This assessment typically considers aspects such as the dispersion of solutions, their distance from the Pareto frontier, or the number of solutions generated.

The JuMENTO repository includes the implementation of common multi-objective metrics:

- **Spacing (SP)**
Measures the dispersion of the solutions in a set with respect to a reference frontier.
- **Generalized Distance (GD)**
  Calculates the average distance of each solution in the set to the closest solution on a reference frontier.
- **Diversity (Δ)**
  Measures how well the solutions are distributed across the objective space.
- **Hypervolume (HV)**
  Quantifies both diversity and convergence by measuring the volume of the objective space dominated by the solution set, relative to a reference (nadir) point.
- **Error Ratio (ER)**
  Indicates the proportion of solutions in the set that are not present in the reference set.
- **Error Metrics (ME, VE, MPE)**
  Accuracy evaluation.

The metrics can be applied by calling their respective functions, as shown below:

```julia
sp = spacing_metric(frontier)
gd = general_distance(frontier, reference)
dm = diversity_metric(frontier, reference)
hv = hypervolume(frontier, [200.0, 100.0])
er = error_ratio(frontier, reference)
me, ve, mpe = calculate_error_metrics(frontier, reference)
```

<!-- Its also possible to print the functions on screen by 

```julia
test_with_get(frontier, reference, [200.0, 150.0])
```

The results will be displayed as follows:

![Metrics](image/Metrics.png) -->

---

## **Example Problems**

To test the implemented multi-objective optimization methods, you can access the "test" folder and check their functionality.

- **Bi-objective**: Simple linear model with two objectives
- **Tri-objective**: Energy planning model with three objectives
- **mokp**: A Multi-objective Knapsack Problem

---

## **References**

### **AUGMECON**

- Mavrotas, G. (2009). "Effective implementation of the epsilon-constraint method in Multi-Objective Mathematical Programming problems." *Applied Mathematics and Computation*, 213(2), 455–465. [DOI: 10.1016/j.amc.2009.03.027](https://doi.org/10.1016/j.amc.2009.03.027)

### **AUGMECON 2**

- Mavrotas, G., & Florios, K. (2013). "An improved version of the augmented ε-constraint method (AUGMECON2) for finding the exact Pareto set in Multi-Objective Integer Programming problems." *Applied Mathematics and Computation*, 219(18), 9652–9669. [DOI: 10.1016/j.amc.2013.03.002](https://doi.org/10.1016/j.amc.2013.03.002)

### **NSGA-II**

- Deb, K., Pratap, A., Agarwal, S., & Meyarivan, T. (2002). "A fast and elitist multiobjective genetic algorithm: NSGA-II." *IEEE Transactions on Evolutionary Computation*, 6(2), 182–197. [DOI: 10.1109/4235.996017](https://doi.org/10.1109/4235.996017)

### **Additional content**

- Coello Coello, C. A. (2002). "Theoretical and numerical constraint-handling techniques used with evolutionary algorithms: A survey of the state of the art." *Computer Methods in Applied Mechanics and Engineering*, 191(11–12), 1245–1287. [https://doi.org/10.1016/S0045-7825(01)00323-1](https://doi.org/10.1016/S0045-7825(01)00323-1)
- Silva, Y. L. T. V., Herthel, A. B., & Subramanian, A. (2019). "A multi-objective evolutionary algorithm for a class of mean-variance portfolio selection problems." *Expert Systems with Applications*, 133, 225–241. [https://doi.org/10.1016/j.eswa.2019.05.018](https://doi.org/10.1016/j.eswa.2019.05.018)
- JuMP Documentation: [https://jump.dev](https://jump.dev)

---
