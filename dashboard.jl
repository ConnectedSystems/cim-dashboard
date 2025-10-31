"""
Quick and dirty dashboard to support workshop.

First load will be a little slower as it tries to run the "base" case and save to disk
to reduce future cold start times.
"""

using Bonito
using WGLMakie

using Serialization

using DataFrames
using CampaspeIntegratedModel


# Ensure temporary data dir for dashboard exists
tmp_dir_db = "data/dashboard_tmp"
if !isdir(tmp_dir_db)
    mkdir(tmp_dir_db)
end

FARM_CLIMATE_FN = "farm_climate.csv"
SW_CLIMATE_FN = "sw_climate.csv"
CLIMATE_DIR = joinpath("data/climate")

function available_farm_options()::Vector{String}
    return String[
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

scenario_template = Dict(
    :start_day => "2025-01-01",
    :end_day => "2030-01-01",
    # Farm parameters
    :farm_climate_path => joinpath(CLIMATE_DIR, "maximum_consensus_rcp45_2016-2045", FARM_CLIMATE_FN),
    :farm_path => "data/farm/basin",
    :farm_step => 14,
    # Policy parameters
    :policy_path => "data/policy",
    :goulburn_alloc => "high",
    :restriction_type => "default",
    :max_carryover_perc => 0.25,
    :carryover_period => 1,
    :dam_extractions_path => "data/policy/eppalock_extractions.csv",
    # Surface water parameters
    :sw_climate_path => joinpath(CLIMATE_DIR, "maximum_consensus_rcp45_2016-2045", SW_CLIMATE_FN),
    :sw_network_path => "data/surface_water/campaspe_network.yml",
)

# Set DataFrameRow to update via UI.
# Use DataFrameRow instead of repeatedly converting Dict to DataFrame and then extracting
# a single row.
scenario = DataFrame(scenario_template)[1, :]

# Create observable type that tracks data that may change
# See: https://juliagizmos.github.io/Observables.jl/stable/
dam_level = Observable(Float64[])

# Load initial data from disk or recreate if not available
# so that initial run does not slow down app launch
init_dl_data_fn = joinpath(tmp_dir_db, "initial_dam_results.dat")
if !isfile(init_dl_data_fn)
    farm_results, dl = CampaspeIntegratedModel.run_model(scenario)
    dam_level[] = dl[1:end-1]  # Ignore last time step
    serialize(init_dl_data_fn, dl[1:end-1])
else
    dam_level[] = deserialize(init_dl_data_fn)
end

# Create base plot to be updated
f1 = Figure(size=(900, 300))
dam_level_ax = Axis(f1[1, 1])
dam_level_ax.ylabel = "Water Level [mAHD]"
dam_level_ax.xlabel = "Days"
ylims!(minimum(dam_level[][1:end-1]) - 1.0, maximum(dam_level[][1:end-1]) + 1.0)
lines!(dam_level_ax, dam_level)

# Create example DataFrame to display as table
# Technically, any Tables.jl-compatible data type should work
# https://simondanisch.github.io/Bonito.jl/stable/widgets.html#Working-with-DataFrames
# table_data = Observable(DataFrame(rand(3, 5), :auto))

RESULTS_CACHE = Dict{String,Vector{Float64}}()

app = App() do
    # Add CSS
    styling = Bonito.Asset(joinpath(@__DIR__, "assets", "db_display.css"))

    farm_option_dropdown = Dropdown(available_farm_options(); index=1)
    policy_option_dropdown = Dropdown(available_policy_options(); index=1)
    climate_option_dropdown = Dropdown(available_climate_scenarios(); index=1)
    run_button = Button("Run")

    climate_scen = parse_option(climate_option_dropdown.value[])
    farm_opt = parse_option(farm_option_dropdown.value[])
    policy_opt = parse_option(policy_option_dropdown.value[])
    cache_key = "$(climate_scen)__$(farm_opt)__$(policy_opt)"
    RESULTS_CACHE[cache_key] = dam_level[]

    on(run_button.value) do click
        climate_scen = parse_option(climate_option_dropdown.value[])
        farm_opt = parse_option(farm_option_dropdown.value[])
        policy_opt = parse_option(policy_option_dropdown.value[])

        # TODO:
        #   Loading/running indicator

        # Create unique hash/key
        cache_key = "$(climate_scen)__$(farm_opt)__$(policy_opt)"
        if cache_key ∉ keys(RESULTS_CACHE)
            @info "Running: $(climate_scen) | $(farm_opt) | $(policy_opt)"

            # Update the scenario spec here!
            climate_data_fn = "$(climate_scen)_rcp45_2016-2045"
            farm_data = joinpath(CLIMATE_DIR, climate_data_fn, FARM_CLIMATE_FN)
            sw_data = joinpath(CLIMATE_DIR, climate_data_fn, SW_CLIMATE_FN)

            scenario.farm_climate_path = farm_data
            scenario.sw_climate_path = sw_data
            # scenario.restriction_type = ...
            # scenario.max_carryover_perc = ...
            # scenario.carryover_period = ...

            # Re-run model and store updated values in the relevant observable
            farm_results, dl = CampaspeIntegratedModel.run_model(scenario)

            # Update table
            # This doesn't work, need to work out why or a potential workaround
            # table_data[] = DataFrame(rand(3, 5), :auto)
            RESULTS_CACHE[cache_key] = dl[1:end-1]  # Ignore last time step
        else
            @info "Re-using cached results for: $(climate_scen) | $(farm_opt) | $(policy_opt)"
        end

        dam_level[] = RESULTS_CACHE[cache_key]
        ylims!(minimum(dam_level[][1:end-1]) - 1.0, maximum(dam_level[][1:end-1]) + 1.0)

        @info "Finished update"
    end

    return DOM.div(
        styling,
        DOM.div(
            class="dashboard-container",
            DOM.div(
                class="control-panel",
                DOM.label("Controls", class="control-title"),
                DOM.div(
                    DOM.label("Climate Scenario", class="control-label"),
                    climate_option_dropdown
                ),
                DOM.div(
                    DOM.label("Policy Options", class="control-label"),
                    policy_option_dropdown
                ),
                DOM.div(
                    DOM.label("Farm Optionality", class="control-label"),
                    farm_option_dropdown
                ),
                DOM.div(
                    run_button
                ),
            ),
            DOM.div(
                class="plots-panel",
                # DOM.h3("Dam Level"),
                DOM.div(f1, class="plots-container"),
                # DOM.div(Bonito.Table(table_data), class="plots-container"),
            ),
            # DOM.div(
            #     class="plots-panel",
            #     DOM.h3("Random"),
            #     DOM.div(f2, class="plots-container")
            # )
        )
    )
end

port = 9384
url = "0.0.0.0"
server = Bonito.Server(app, url, port)
