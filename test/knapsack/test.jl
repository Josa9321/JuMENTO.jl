function buggy_load_instances()
    instances_2objs = ["2kp50.xlsx", "2kp100.xlsx", "2kp250.xlsx", "2kp500.xlsx", "2kp750.xlsx"]
    buggy_load_instances_set(instances_2objs)
    
    instances_3objs = ["3kp40.xlsx", "3kp50.xlsx"]
    buggy_load_instances_set(instances_3objs)

    instances_4objs = ["4kp40.xlsx", "4kp50.xlsx"]
    buggy_load_instances_set(instances_4objs)
    return false
end

function buggy_load_instances_set(addresses_set)
    for instance_name in addresses_set
        instance::KnapsackInstance = load_instance(merge_with_folder(instance_name))
        @assert instance.I.stop == parse(Int64, instance_name[4:end-5]) "The number of jobs is wrong, should be $(instance_name[4:end-5]) instead of $(instance.I.stop)"
        @assert instance.O.stop == parse(Int64, instance_name[1]) "The number of objectives is wrong, should be $(instance_name[1]) instead of $(instance.O.stop)"
    end
    return false
end

function merge_with_folder(instance_address)
    return "test//knapsack//instances//" * instance_address
end