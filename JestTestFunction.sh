###############################Clone the repo passed as a param#######################################
copado -p 'Cloning the repository' 
mkdir JestProject
cd JestProject
git clone $repo -b "$branch" .
#copado-git-get -d . "$branch"
###############################Installing jest libs via npm#########################
copado -p 'Installing jest'
npm init -y
npm i --sav-dev jest
#path="force-app/main/default/lwc/lwcOne/__tests__/lwcOne.test.js"
##############################Setting LWCs to run jest on################################
copado -p 'Retrieveing LWCs to test'
jestCommandString=""
IFS=',' read -r -a array <<< "$lwcList"
#echo 'before for loop'
for element in "${array[@]}"
do
	individualLwcPath="$pathToLwcs${element}/__tests__/${element}.test.js"
    #echo 'after individual'
	jestCommandString="$jestCommandString $individualLwcPath "
    #echo $path
    #echo $individualLwcPath 
done
###############################Run all jest tests in cloned repo######################################
copado -p 'Running Jest Suite'
./node_modules/.bin/jest --findRelatedTests $jestCommandString --outputFile=/tmp/result.json --json --testFailureExitCode 0
#./node_modules/.bin/jest --outputFile=/tmp/result.json --json --testFailureExitCode 0
cat /tmp/result.json | python -m json.tool > /tmp/jestResults.json

###############################Attach the test results to result record###############################
copado -p 'Attaching Result File' 
copado --uploadfile /tmp/jestResults.json

#######################If the failed tests is greater than passed threshold kill the funciton###############
failedTestCount=$(jq '.numFailedTestSuites' /tmp/jestResults.json)
copado -p 'Determining failed test count'
echo $failedTestCount
if [ "$failedTestCount" -gt "$failedTestLimit" ]
then
	echo "exiting 1"
	exit 1
fi
