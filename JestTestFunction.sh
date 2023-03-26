###############################Clone the repo passed as a param#######################################
copado -p 'Cloning the repository' 
#mkdir JestProject
#cd JestProject
git clone $repo -b "$branch" .
sfdx force:config:set instanceUrl=https://slalomorg.my.salesforce.com --global
#copado-git-get -d . "$branch"
###############################Installing jest libs via npm#########################
copado -p 'Installing jest'
npm init -y
sfdx force:lightning:lwc:test:setup
node --experimental-vm-modules ./node_modules/jest/bin/jest.js
echo "Before Version"
##############################Setting LWCs to run jest on################################
copado -p 'Retrieveing LWCs to test'
jestCommandString=""
IFS=',' read -r -a array <<< "$lwcList"
for element in "${array[@]}"
do
	individualLwcPath="$pathToLwcs${element}/__tests__/${element}.test.js"
	jestCommandString="$jestCommandString $individualLwcPath "
done
###############################Run all jest tests in cloned repo######################################
copado -p 'Running Jest Suite'
./node_modules/.bin/jest --findRelatedTests $jestCommandString --outputFile=/tmp/result.json --json --testFailureExitCode 0
cat /tmp/result.json | python -m json.tool > /tmp/jestResults.json

###############################Attach the test results to result record###############################
copado -p 'Attaching Result File' 
copado --uploadfile /tmp/jestResults.json
#######################Determine if the tests passed############
failedTestCount=$(jq '.numFailedTestSuites' /tmp/jestResults.json)
copado -p 'Determining failed test count'
echo $failedTestCount
########################Write result back to user story##########################
#sfdx force:config:set instanceUrl=https://login.salesforce.com --global
if [ "$failedTestCount" -gt "$failedTestLimit" ]
then
	sfdx force:data:record:update -s copado__User_Story__c -i $usId -v "Jest_Test_Result__c='Fail'" --targetusername $dxSessionId
	echo "exiting 1"
	#exit 1
else
	sfdx force:data:record:update -s copado__User_Story__c -i $usId -v "Jest_Test_Result__c='Pass'" --targetusername $dxSessionId
fi
