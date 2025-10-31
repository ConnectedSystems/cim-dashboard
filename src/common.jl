# Ensure temporary data dir for dashboard exists
tmp_dir_db = "data/dashboard_tmp"
if !isdir(tmp_dir_db)
    mkdir(tmp_dir_db)
end

FARM_CLIMATE_FN = "farm_climate.csv"
SW_CLIMATE_FN = "sw_climate.csv"
CLIMATE_DIR = joinpath("data/climate")
