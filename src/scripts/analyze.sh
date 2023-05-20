#!/bin/bash


cat << EOF
################################################################################
################################################################################
##############################################     #############################
#####################/     ########((.######     *   ###########################
###################       *   (                  #/    #########################
#################          /                    # ##*  .########################
################/          (                      ##############################
##################         ,#                   ### ############################
####################      /##      #####         ## ############################
######################*####        ####,             ###########################
######################                                 #########################
#######################                        ######.  ########################
#######################                          ###    ########################
##########################         #              (    #########################
############################          ##*      *#####,           ,##############
############################       /##(  ,#####                #  ##############
############################        #                         ##  ##############
##########################          #/                ###    ###, ##############
#######################             /#              ############# ##############
####################(          #     #      .##.   ############## ,#############
###################             *#   #.    ######################  #############
###################              .# ,##  #################(        #############
#####################             #####  ####*         #########################
#######################           #####  (######################################
#########################        ###############################################
################################################################################
#####       #######  (###        ###  *#####       #######     #######     /####
#####  #####  (###  / *#####  #####  ( .####  #####  /#.  #####  ##   ##########
#####  ######  ##  ##( .####  ####  ###  ###  ######  #  ######(  #  ###    ####
#####  #####  ##  ####*  ###  ###  ####/  ##  #####  ##(  #####  ##.  ####  ####
#####      (###  ######(  ##  ##  #######  #      /#######*   (#######,   .#####
################################################################################
EOF

########################################################
# install Java
########################################################
echo -n "Install dependencies ... "
sudo apt-get update >/dev/null 2>&1
sudo apt-get install --yes openjdk-17-jdk >/dev/null 2>&1
sudo apt-get install --yes unzip >/dev/null 2>&1
echo "done"

########################################################
# check variables
########################################################
if [ -z "$DD_API_KEY" ]; then
    echo "DD_API_KEY not set. Please set one and try again."
    exit 1
fi

if [ -z "$DD_APP_KEY" ]; then
    echo "DD_APP_KEY not set. Please set one and try again."
    exit 1
fi

if [ -z "$DD_ENV" ]; then
    echo "DD_ENV not set. Please set this variable and try again."
    exit 1
fi

if [ -z "$DD_SERVICE" ]; then
    echo "DD_SERVICE not set. Please set this variable and try again."
    exit 1
fi

PROJECT_ROOT=$(pwd)

########################################################
# static analyzer tool stuff
########################################################
echo -n "Install datadog static analyzer ... "
TOOL_DIRECTORY=$(mktemp -d)

if [ ! -d "$TOOL_DIRECTORY" ]; then
    echo "Tool directory $TOOL_DIRECTORY does not exist"
    exit 1
fi

cd "$TOOL_DIRECTORY" || exit 1
curl -L -O http://dtdg.co/latest-static-analyzer >/dev/null 2>&1 || exit 1
unzip latest-static-analyzer > /dev/null 2>&1 || exit 1
CLI_LOCATION=$TOOL_DIRECTORY/cli-1.0-SNAPSHOT/bin/cli
echo "done"

########################################################
# datadog-ci stuff
########################################################
echo -n "Install datadog-ci ..."
sudo /usr/local/bin/npm install -g @datadog/datadog-ci || exit 1

DATADOG_CLI_PATH=/usr/local/bin/datadog-ci

# Check that datadog-ci was installed
if [ ! -x $DATADOG_CLI_PATH ]; then
    echo "The datadog-ci was not installed correctly, not found in $DATADOG_CLI_PATH."
    exit 1
fi
echo "done: datadog-ci available $DATADOG_CLI_PATH"

########################################################
# output directory
########################################################
echo -n "Getting output directory ... "
OUTPUT_DIRECTORY=$(mktemp -d)

# Check that datadog-ci was installed
if [ ! -d "$OUTPUT_DIRECTORY" ]; then
    echo "Output directory ${OUTPUT_DIRECTORY} does not exist"
    exit 1
fi

OUTPUT_FILE="$OUTPUT_DIRECTORY/output.sarif"

echo "done: will output results at ${OUTPUT_FILE}"

########################################################
# execute the tool and upload results
########################################################

echo -n "Starting a static analysis ..."
$CLI_LOCATION --directory "${PROJECT_ROOT}" -t true -o "${OUTPUT_FILE}" -f sarif || exit 1
echo "done"


echo -n "Uploading results to Datadog ..."
${DATADOG_CLI_PATH} sarif upload "${OUTPUT_FILE}" --service "${DD_SERVICE}" --env "$DD_ENV"
echo "Done"
