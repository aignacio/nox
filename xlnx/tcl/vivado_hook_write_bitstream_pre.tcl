# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

set workroot [file dirname [info script]]

send_msg "Designcheck 1-1" INFO "Checking design"

# Ensure the design meets timing
# OR MAYBE EVERYTHING WAS OPTZ OUT
set slack_ns [get_property SLACK [get_timing_paths -delay_type min_max]]
send_msg "Designcheck 1-2" INFO "Slack is ${slack_ns} ns."

if [expr {$slack_ns < 0}] {
  send_msg "Designcheck 1-3" ERROR "Timing failed. Slack is ${slack_ns} ns."
}

#Timestamp
#The USR_ACCESS register can be configured with a 32-bit user-specified value or automatically loaded by the bitstream generation command (write_bitstream) with a timestamp. The user-specified value can be used for revision, design tracking, or serial number type applications. The timestamp feature is useful when several implementation runs have been performed, thereby changing design optimization values, but the source design itself is unchanged. The timestamp value can then be compared to the timestamp for the bitstream file to correlate the design in the device to one of the many possible sources. The timestamp feature is not easily implemented by changing the source code. Implementing the USR_ACCESS method provides a more accurate timestamp.
# Enable bitstream identification via USR_ACCESS register.
set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]

# Allow not fully constrained in/out pins in XDC
set_property BITSTREAM.General.UnconstrainedPins {Allow} [current_design]
