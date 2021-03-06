#!/bin/bash

#Variables needed by script and example data:
#dataset_id=AFG
#dataset_name=AFG Baseline Data
#dataset_description
#tags='[{"name":"AFG"}, {"name":"Afghanistan"}, {"name":"baseline"},{"name":"preparedness"}]'
#group_id=AFG
#org_id=hdx   #optional


#error string that's used to check for errors
ERROR_GREP="\"success\": false\|Bad request - JSON Error"

#Check if package exists or we need to create it
action=package_show
action_file=$LOG_FOLDER/tmp_$action.$dataset_id.log
#see if the package already exists
curl -s $CKAN_INSTANCE/api/3/action/$action \
	--data '{	"id":"'$dataset_id'" }' \
	-H Authorization:$CKAN_APIKEY > $action_file
result=`cat $action_file | grep "$ERROR_GREP"`
if [ -z "$result" ]; then
	echo "Dataset "$dataset_id" exists! Updating ..."
    action=package_update
    extra_json="\"id\":\"$dataset_id\","
else
	echo "Not found dataset "$dataset_id"! Creating ..."
	action=package_create
	extra_json=""
fi

if [ "$org_id" ]; then
	extra_json=$extra_json" \"owner_org\":\"$org_id\", "
fi

if [ "$dataset_description" ]; then
	extra_json=$extra_json" \"notes\":\"$dataset_description\", "
fi

if [ "$tags" ]; then
	extra_json=$extra_json" \"tags\":"$tags", "
else
	#keep existing tags:
	existing_tags=`cat $action_file | ./json/JSON.sh/JSON.sh | egrep '\["result","tags"]'`
	existing_tags=${existing_tags:18}
	existing_tags=`echo ${existing_tags}`
	echo "Existing tags:"$existing_tags
	tags=$existing_tags

	extra_json=$extra_json" \"tags\":"$tags", "
fi


if [ "$ckan_source" ]; then
	extra_json=$extra_json" \"dataset_source\":\"$ckan_source\", "
fi

if [ "$ckan_license_id" ]; then
	extra_json=$extra_json" \"license_id\":\"$ckan_license_id\", "
fi

if [ "$ckan_date_min" ]; then
	extra_json=$extra_json" \"dataset_date\":\"01/01/$ckan_date_min-12/31/$ckan_date_max\", "
fi

if [ "$ckan_methodology" ]; then
	extra_json=$extra_json" \"methodology\":\"$ckan_methodology\", "
fi

if [ "$ckan_caveats" ]; then
	extra_json=$extra_json" \"caveats\":\"$ckan_caveats\", "
fi

#create package
#action is set in the previous step
action_file=$LOG_FOLDER/tmp_$action.$dataset_id.log
curl -s $CKAN_INSTANCE/api/3/action/$action \
	--data '{	'"$extra_json"'
				"name":"'"$dataset_id"'",
				"title":"'"$dataset_name"'",
				"state":"active",
				"groups":[{"id":"'"$group_id"'"}],
				"package_creator": "import-script"
			}' \
	-H Authorization:$CKAN_APIKEY > $action_file
result=`cat $action_file | grep "$ERROR_GREP"`
if [ "$result" ]; then
	echo "<<<ERROR while executing action "$action" on dataset "$dataset_id" with name: "$dataset_name
fi
extra_json=
echo "Done adding/updating dataset "$dataset_id" with title: "$dataset_name
