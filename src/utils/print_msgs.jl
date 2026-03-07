"""
    println_if_necessary(message, options)

Prints `message` only when `options[:print_level] > 0`.

# Arguments
- `message`: Any object printable with `println`.
- `options::Dict`: Options dictionary containing `:print_level`.
"""
function println_if_necessary(message, options)
    if options[:print_level]::Int64 > 0
        println(message)
    end
    return
end

"""
    printf_if_necessary(options, message_format, variables...)

Formats and prints a message only when `options[:print_level] > 0`.

# Arguments
- `options::Dict`: Options dictionary containing `:print_level`.
- `message_format`: A `Printf` format pattern.
- `variables...`: Values interpolated into the format pattern.
"""
function printf_if_necessary(options, message_format, variables...)
    if options[:print_level]::Int64 > 0
        message_to_print = Printf.format(Printf.Format(message_format), variables...)
        println(message_to_print)
    end
    return 
end