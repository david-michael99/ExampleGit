#!/bin/bash
#
#
#+-------------------------------------------------------------+
#|    Author : DOM                                      |
#|    Date   : 13/03/2024                                      |
#|                                                             |
#|    Copyright (C) 2024 Liverpool Data Research Associates    |
#+-------------------------------------------------------------+

#Configure variables that are likely to change
#=============================================
TBED=/home/ldra-runner/ldra_toolsuite
WORK=/home/ldra-runner/ldra_workarea
PRJ=Cashregister
COMPILER=GCC
export PATH=${TBED}:${PATH}
ROOT=${WORK}/examples/toolsuite/Cashregister_7.0
CONFIG_DIR=${ROOT}/Configuration
START_TIME=$(date +%s)

#Configure relative paths 
#========================
SRC_FILES=${ROOT}/${PRJ}.tcf
WORK_DIR=${WORK}/${PRJ}_tbwrkfls

if [ -e "$TBED/contestbed" ]; then
  TOOL='contestbed'
fi
if [ -f "$TBED/conunit" ]; then
  TOOL='conunit'
fi

#Delete the existing set and work directory
#==========================================
echo "Deleting Existing Results"
${TOOL} /delete_set=${PRJ}

if [ -f "${WORK_DIR}" ]; then
  rm -rf ${WORK_DIR}
fi

#Set up necessary testbed.ini options
#====================================
echo "Configuring Testbed.ini"
tbini COMPILER_SELECTED="$COMPILER"
tbini "Section=C/C++ ${COMPILER} LDRA Testbed" CM_TOOL_SELECTED=Subversion
tbini "Section=C/C++ ${COMPILER} LDRA Testbed" CM_ADD_VERSION_TO_REPORTS=TRUE
tbini "Section=C/C++ ${COMPILER} LDRA Testbed" DYNAMIC_REPORT_CONFIGURATION=DO-178C Level A
tbini "Section=C/C++ ${COMPILER} LDRA Testbed" FILE_LIMIT=32
tbini "Section=C/C++ ${COMPILER} LDRA Testbed" TBRUN_LOCAL_STUB_HIT_COUNTS=TRUE
tbini "Section=C/C++ ${COMPILER} LDRA Testbed" TBRUN_TC_JMP=TRUE
tbini "Section=C/C++ ${COMPILER} LDRA Testbed" METFILE=${CONFIG_DIR}/metpen.dat
tbini "Section=C/C++ ${COMPILER} LDRA Testbed" TBRUN_IMPORT_TBED_COMMANDS=FALSE

#Create output log
#=================
TCF_ROOT=${ROOT}/LowLevelTests
cd ${TCF_ROOT}
if [ -e "LLT.log" ]; then
  rm -rf LTT.log #Remove old log
fi
touch LLT.log #Create new log

#Run the Main Static, Complexity Analysis, Data Flow, Information Flow & Instrumentation
#=======================================================================================
echo "Running Analysis and Instrumentation"
${TOOL} ${SRC_FILES} 112a34021q 

#Run each sequence in the TCF directory
#======================================
#Count tests
TESTS=0
for i in *.tcf
do
  TESTS=$((${TESTS}+1)) #Count total tests.
done
echo "Total tests to process: ${TESTS}"
#Run each test
TEST=0
for j in *.tcf
do
  TEST=$((${TEST}+1))
  echo "${TEST}/${TESTS} : $j"
  ${TOOL} ${SRC_FILES} 1q -tbruntcf="${ROOT}/LowLevelTests/$j" -tbruntcfargs="-regress -quit" >> LLT.log
done

#Generate a Test Manager Report
#==============================
echo "Generating a Test Manager Report"
${TOOL} ${SRC_FILES} -generate_overview_rep
TEST_MANAGER_REPORT="${WORK_DIR}/${PRJ}_reports/${PRJ}.ovs.htm"

#Display Execution Time
#======================
END_TIME=$(date +%s)
RUN_TIME=$((END_TIME-START_TIME))
HOURS=$((RUN_TIME/3600))
MINS=$(((RUN_TIME/60)-(60*${HOURS})))
SEC=$((($RUN_TIME)-($MINS*60)-($HOURS*3600)))
echo "Time taken ${HOURS}:${MINS}:${SEC}"


