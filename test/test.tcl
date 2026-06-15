#============================================================
# UART_CONTROLLER regression script for Vivado
#============================================================

#set baudrates {300 600 1200 1800 2400 3600 4800 7200 9600 14400 19200 28800 38400 57600 115200 230400 460800 921600} for all tests

# fast test
set baudrates {57600 115200 230400 460800 921600}
set ratios    {8 16 32}
set parities  {0 1 2}
set stops     {0 1}

set total_cases 0
set failed_cases 0

# Optional: log file
set script_dir [file dirname [file normalize [info script]]]
set log_file_name "$script_dir/uart_regression_result.log"
set log_file [open $log_file_name "w"]

puts "Script directory: $script_dir"
puts "Log file: $log_file_name"

puts $log_file "UART_CONTROLLER regression started"
puts $log_file "============================================================"

foreach baudrate $baudrates {
    foreach ratio $ratios {
        foreach parity $parities {
            foreach stop $stops {

                incr total_cases

                set define_list [list \
                    TB_BAUDRATE_D=$baudrate \
                    TB_RATIO_D=$ratio \
                    TB_PARITY_BIT_D=$parity \
                    TB_STOP_BIT_D=$stop \
                ]

                puts "============================================================"
                puts "CASE $total_cases"
                puts "BAUDRATE   = $baudrate"
                puts "RATIO      = $ratio"
                puts "PARITY_BIT = $parity"
                puts "STOP_BIT   = $stop"
                puts "============================================================"

                puts $log_file "CASE $total_cases: BAUDRATE=$baudrate RATIO=$ratio PARITY_BIT=$parity STOP_BIT=$stop"

                # Close previous simulation if it is opened
                catch {close_sim -force}

                # Clean/restart simulation state
                reset_simulation -simset sim_1

                # Set Verilog defines
                set_property verilog_define $define_list [get_filesets sim_1]

                # Launch simulation
                launch_simulation

                # Run testbench
                run all

                # Check simulation objects after finish
                # Assumes your testbench has integer/reg signal named "errors"
                set case_errors 0

                if {[catch {set case_errors [get_value -radix unsigned /UART_CONTROLLER_TB/errors]}]} {
                    puts "WARNING: Could not read /UART_CONTROLLER_TB/errors"
                    puts $log_file "    WARNING: Could not read errors signal"
                    set case_errors 1
                }

                if {$case_errors != 0} {
                    incr failed_cases
                    puts "CASE $total_cases RESULT: FAIL, errors=$case_errors"
                    puts $log_file "    RESULT: FAIL, errors=$case_errors"
                } else {
                    puts "CASE $total_cases RESULT: PASS"
                    puts $log_file "    RESULT: PASS"
                }

                puts $log_file "------------------------------------------------------------"
                flush $log_file
            }
        }
    }
}

puts "============================================================"
puts "UART_CONTROLLER regression finished"
puts "TOTAL CASES  = $total_cases"
puts "FAILED CASES = $failed_cases"
puts "============================================================"

puts $log_file "============================================================"
puts $log_file "UART_CONTROLLER regression finished"
puts $log_file "TOTAL CASES  = $total_cases"
puts $log_file "FAILED CASES = $failed_cases"
puts $log_file "============================================================"

close $log_file

if {$failed_cases != 0} {
    error "UART regression failed: $failed_cases case(s) failed"
}