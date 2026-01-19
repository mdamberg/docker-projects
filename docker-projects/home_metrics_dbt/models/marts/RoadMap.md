# ------------------------------------------------------------------------------ #
#                  Data Mart Direction and Road Map
# ------------------------------------------------------------------------------ #

## Sources:

#### 1. System Health (Server Desktop) 
    - Establish informative and diagnosistc models which provide key information on server health, power usage and it contributions to the overall stack.
#### dim_hardware_entrity (Dimensional Table)
    - **TABLE GRAIN:** 1 row per QUARTER HOUR TIME STAMP
    - Provide a look up and unique assaignment for each hardware entitiy and tracking component
        - System Health ID, host name, recorded date and ts, inserted date as ts 
        - Metrics for system health
