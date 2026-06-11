#!/bin/bash
set -e

#Clean and Compile
make clean
make compile

#to generate a fresh testlist with random seeds
generate_testlist() {
    local tests=("base" "multi" "high_addr" "nak")
    local iterations=1
    
    #for Clear/Create the testlist file
    > testlist
    
    for test_name in "${tests[@]}"; do
        for i in $(seq 1 $iterations); do
            # Generate a 32-bit random seed
            seed=$(shuf -i 1-2147483647 -n 1)
            # Write to testlist in the requested format
            echo "+TESTNAME=$test_name +ntb_random_seed=$seed" >> testlist
        done
    done
    echo "Generated testlist with $(( ${#tests[@]} * iterations )) entries."
}

#for running the generator function
generate_testlist

#for reading from the newly created testlist and execute
while IFS= read -r line || [ -n "$line" ]; do
    test_name=$(echo "$line" | grep -oP '\+TESTNAME=\K[^ ]+')
    seed=$(echo "$line" | grep -oP '\+ntb_random_seed=\K[0-9]+')

    echo "Running: $test_name | Seed: $seed"

    #for unning simulation
    vsim -c -coverage optimized_debug_top_tb \
         -do "coverage save -onexit sim_${test_name}_s${seed}.ucdb; run -all; quit -f" \
         +TESTNAME="$test_name" +ntb_random_seed="$seed"

done < testlist

if ls sim_*.ucdb 1> /dev/null 2>&1; then
    vcover merge merged_tests.ucdb sim_*.ucdb
    make convert
    make merge
    make view
else
    echo "ERROR: No UCDB files found - all simulations may have failed"
    exit 1
fi
