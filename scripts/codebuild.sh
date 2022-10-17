# Parameters required:
# DB_NAME - name of database
# BRANCH_NAME - name of branch (extract from git branch)
# ORG_NAME - name of planetscale organisation
# PS_TOKEN - this is taken from PlanetScale as a ServiceToken
# PS_TOKEN_ID - this is taken from PlanetScale as a ServiceToken


# list branch connection strings thta exist
raw_output=`pscale password list "$DB_NAME" "$BRANCH_NAME" --org "$ORG_NAME" --format json --service-token "$PS_TOKEN" --service-token-id "$PS_TOKEN_ID"`
# check return code, if not 0 then error
if [ $? -ne 0 ]; then
    echo "Error: pscale password list returned non-zero exit code $?: $raw_output"
    exit 1
fi

# CREDS is like the passwordname
output=`echo $raw_output | jq -r "[.[] | select(.display_name == \"$ORG_NAME+creds\") ] | .[0].id "`
# if output is not "null", then password exists, delete it
if [ "$output" != "null" ]; then
    echo "Deleting existing password $output"
    pscale password delete --force "$DB_NAME" "$BRANCH_NAME" "$output" --org "$ORG_NAME" --service-token "$PS_TOKEN" --service-token-id "$PS_TOKEN_ID"
    # check return code, if not 0 then error
    if [ $? -ne 0 ]; then
        echo "Error: pscale password delete returned non-zero exit code $?"
        exit 1
    fi
fi

raw_output=`pscale password create "$DB_NAME" "$BRANCH_NAME" "$ORG_NAME+creds" --org "$ORG_NAME" --format json --service-token "$PS_TOKEN" --service-token-id "$PS_TOKEN_ID`

if [ $? -ne 0 ]; then
    echo "Failed to create credentials for database $DB_NAME branch $BRANCH_NAME: $raw_output"
    exit 1
fi

# pscale password create bookshop dev elliott-coleman creds-dev sharesecret --format json | jq -r ". | \"mysql://\" + .id +  \":\" + .plain_text +  \"@\" + .database_branch.access_host_url + \"/\""

# Use this when configuring the lightsail container
DB_URL=`echo "$raw_output" |  jq -r ". | \"mysql://\" + .id +  \":\" + .plain_text +  \"@\" + .database_branch.access_host_url + \"/\""`

# This line will create a deploy request from the "$BRANCH_NAME" branch, and is outputting JSON.
# It's piping the JSON to `jq`, which is reading the Deploy Request number to the DR_NUM variable.
DR_NUM=$(pscale deploy-request create bookings_api "$BRANCH_NAME" --service-token $PS_TOKEN --service-token-id $PS_TOKEN_ID --org $PS_ORG --format json | jq '.number' )

# This line grabs the Deploy Request and stores the state in DR_STATE
DR_STATE=$(pscale deploy-request show bookings_api $DR_NUM --service-token $PS_TOKEN --service-token-id $PS_TOKEN_ID --org $PS_ORG --format json | jq -r '.deployment.state')

# This loop will wait until PlanetScale has finished checking to see if changes can be applied before moving forward.
while [ "$DR_STATE" = "pending" ];
do
  sleep 5
  DR_STATE=$(pscale deploy-request show bookings_api $DR_NUM --service-token $PS_TOKEN --service-token-id $PS_TOKEN_ID --org $PS_ORG --format json | jq -r '.deployment.state')
  echo "State: $DR_STATE"
done

# Once the state has been updated, we're going to check the state to decide how to proceed.
if [ "$DR_STATE" = "no_changes" ]; then
	# If the state is "no_change", close the request without applying changes.
  pscale deploy-request close bookings_api $DR_NUM --service-token $PS_TOKEN --service-token-id $PS_TOKEN_ID --org $PS_ORG
else
	# If its anything else, attempt to deploy (merge) the changes into the `main` branch.
  pscale deploy-request deploy bookings_api $DR_NUM --service-token $PS_TOKEN --service-token-id $PS_TOKEN_ID --org $PS_ORG
fi