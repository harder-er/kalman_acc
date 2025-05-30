# 
# Synthesis run script generated by Vivado
# 

set TIME_start [clock seconds] 
namespace eval ::optrace {
  variable script "D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.runs/synth_1/KalmanFilterTop.tcl"
  variable category "vivado_synth"
}

# Try to connect to running dispatch if we haven't done so already.
# This code assumes that the Tcl interpreter is not using threads,
# since the ::dispatch::connected variable isn't mutex protected.
if {![info exists ::dispatch::connected]} {
  namespace eval ::dispatch {
    variable connected false
    if {[llength [array get env XILINX_CD_CONNECT_ID]] > 0} {
      set result "true"
      if {[catch {
        if {[lsearch -exact [package names] DispatchTcl] < 0} {
          set result [load librdi_cd_clienttcl[info sharedlibextension]] 
        }
        if {$result eq "false"} {
          puts "WARNING: Could not load dispatch client library"
        }
        set connect_id [ ::dispatch::init_client -mode EXISTING_SERVER ]
        if { $connect_id eq "" } {
          puts "WARNING: Could not initialize dispatch client"
        } else {
          puts "INFO: Dispatch client connection id - $connect_id"
          set connected true
        }
      } catch_res]} {
        puts "WARNING: failed to connect to dispatch server - $catch_res"
      }
    }
  }
}
if {$::dispatch::connected} {
  # Remove the dummy proc if it exists.
  if { [expr {[llength [info procs ::OPTRACE]] > 0}] } {
    rename ::OPTRACE ""
  }
  proc ::OPTRACE { task action {tags {} } } {
    ::vitis_log::op_trace "$task" $action -tags $tags -script $::optrace::script -category $::optrace::category
  }
  # dispatch is generic. We specifically want to attach logging.
  ::vitis_log::connect_client
} else {
  # Add dummy proc if it doesn't exist.
  if { [expr {[llength [info procs ::OPTRACE]] == 0}] } {
    proc ::OPTRACE {{arg1 \"\" } {arg2 \"\"} {arg3 \"\" } {arg4 \"\"} {arg5 \"\" } {arg6 \"\"}} {
        # Do nothing
    }
  }
}

proc create_report { reportName command } {
  set status "."
  append status $reportName ".fail"
  if { [file exists $status] } {
    eval file delete [glob $status]
  }
  send_msg_id runtcl-4 info "Executing : $command"
  set retval [eval catch { $command } msg]
  if { $retval != 0 } {
    set fp [open $status w]
    close $fp
    send_msg_id runtcl-5 warning "$msg"
  }
}
OPTRACE "synth_1" START { ROLLUP_AUTO }
set_msg_config -id {Common 17-41} -limit 10000000
OPTRACE "Creating in-memory project" START { }
create_project -in_memory -part xc7vx485tffg1157-1

set_param project.singleFileAddWarning.threshold 0
set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_msg_config -source 4 -id {IP_Flow 19-2162} -severity warning -new_severity info
set_property webtalk.parent_dir D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.cache/wt [current_project]
set_property parent.project_path D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.xpr [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language Verilog [current_project]
set_property ip_output_repo d:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.cache/ip [current_project]
set_property ip_cache_permissions {read write} [current_project]
OPTRACE "Creating in-memory project" END { }
OPTRACE "Adding files" START { }
read_verilog -library xil_defaultlib -sv {
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CEU_a.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CEU_alpha.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CEU_d.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CEU_division.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CEU_x.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CMU_PHi11.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CMU_PHi12.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CMU_PHi13.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CMU_PHi14.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CMU_PHi21.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CMU_PHi22.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CMU_PHi23.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CMU_PHi24.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CMU_PHi31.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CMU_PHi32.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CMU_PHi33.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CMU_PHi34.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CMU_PHi41.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CMU_PHi42.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CMU_PHi43.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CMU_PHi44.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/CovarianceUpdate.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/DelayUnit.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/F_make.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/KF_ControlUnit.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/KalmanGainCalculator.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/MatrixInverseUnit.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/MatrixTransBridge.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/ProcessingElement.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/StatePredictor.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/StateUpdate.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/SystolicArray.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/fp_adder.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/fp_multiplier.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/fp_suber.sv
  D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/new/kalman_acc_top.sv
}
read_ip -quiet D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/ip/floating_point_sub/floating_point_sub.xci

read_ip -quiet D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/ip/floating_point_add/floating_point_add.xci

read_ip -quiet D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/ip/floating_point_mul/floating_point_mul.xci

read_ip -quiet D:/zgh/direction/kalman_rtl/kalman_acc_sv/kalman_acc_sv.srcs/sources_1/ip/floating_point_div/floating_point_div.xci

OPTRACE "Adding files" END { }
# Mark all dcp files as not used in implementation to prevent them from being
# stitched into the results of this synthesis run. Any black boxes in the
# design are intentionally left as such for best results. Dcp files will be
# stitched into the design at a later time, either when this synthesis run is
# opened, or when it is stitched into a dependent implementation run.
foreach dcp [get_files -quiet -all -filter file_type=="Design\ Checkpoint"] {
  set_property used_in_implementation false $dcp
}
read_xdc dont_touch.xdc
set_property used_in_implementation false [get_files dont_touch.xdc]
set_param ips.enableIPCacheLiteLoad 1
close [open __synthesis_is_running__ w]

OPTRACE "synth_design" START { }
synth_design -top KalmanFilterTop -part xc7vx485tffg1157-1
OPTRACE "synth_design" END { }
if { [get_msg_config -count -severity {CRITICAL WARNING}] > 0 } {
 send_msg_id runtcl-6 info "Synthesis results are not added to the cache due to CRITICAL_WARNING"
}


OPTRACE "write_checkpoint" START { CHECKPOINT }
# disable binary constraint mode for synth run checkpoints
set_param constraints.enableBinaryConstraints false
write_checkpoint -force -noxdef KalmanFilterTop.dcp
OPTRACE "write_checkpoint" END { }
OPTRACE "synth reports" START { REPORT }
create_report "synth_1_synth_report_utilization_0" "report_utilization -file KalmanFilterTop_utilization_synth.rpt -pb KalmanFilterTop_utilization_synth.pb"
OPTRACE "synth reports" END { }
file delete __synthesis_is_running__
close [open __synthesis_is_complete__ w]
OPTRACE "synth_1" END { }
