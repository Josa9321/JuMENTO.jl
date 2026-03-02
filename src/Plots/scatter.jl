function scatter_plot(frontier)
    if size(frontier, 1) == 2
        x = frontier[1, :]
        y = frontier[2, :]
        scatter(x, y)
    elseif size(frontier, 1) == 3
        x = frontier[1, :]
        y = frontier[2, :]
        z = frontier[3, :]
        scatter(x, y, z)
    else

    end
end
