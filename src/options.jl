"""Define available dashboard control options."""

function available_farm_options()::Vector{String}
    return String[
        "Default",
        "Improve Irrigation Efficiency",
        "Implement Solar Panels",
        "Adopt Drought Resistant Crops",
        "Improve Soil Taw",
        "Increase Farm Entitlements",
        "Decrease Farm Entitlements"
    ]
end

function available_policy_options()::Vector{String}
    return String[
        "Default",
        "Implement Coupled Allocations",
        "Increase Environmental Water",
        "Decrease Environmental Water",
        "Increase Water Price",
        "Decrease Water Price",
        "Raise Dam Level",
        "Subsidise Irrigation Efficiency",
        "Subsidise Solar Pump"
    ]
end

function available_climate_scenarios()::Vector{String}
    return String[
        "Maximum Consensus",
        "Best Case",
        "Worst Case"
    ]
end

"""
    parse_option(opt::String)::String

Parse control options back to matching option identifier.

# Example
```julia
parse_option("Improve Irrigation Efficiency")
# improve_irrigation_efficiency
```
"""
function parse_option(opt::String)::String
    return lowercase(replace(opt, " " => "_"))
end
