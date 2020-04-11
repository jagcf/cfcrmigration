#!/bin/bash

functionApiCall(){

    echo " api call for $1 $2 $3"
    curl -X GET $1 \
                    -H 'Authorization: '$2 > $3 \
                 

  status=`cat $3 | jq '.status'`
  echo $status
  if  [ -n $status ] && [ $status -eq 401 ]
   then
      echo " Authenticaiton error.Please check your api key and try again"
      cat $3
      if  [ $4 ]
       then
         exit 1;
      fi
   fi
} 

function1 () {
  echo "starting retrieveing all repo urls"

  pipsMetaUrl="https://g.codefresh.io/api/pipelines?includeBuilds=false&limit=200&offset=0"


  allPipsMetadata=$2"_allPipsMetadata"

   echo '****** Step .1) Invoking '$pipsMetaUrl' to collect all pipelines detailed metadata into a file '$allPipsMetadata".json"
  rm $allPipsMetadata".json"
  functionApiCall $pipsMetaUrl $1 $allPipsMetadata".json" true

  status=`cat $allPipsMetadata".json" | jq '.status'`
  echo $status
  if [ $status -eq 401 ]
   then
      echo " Authenticaiton error.Please check your api key and try again"
      cat $allPipsMetadata".json"
      exit 1;
   fi

  echo '****** Step 1) generating '$allPipsMetadata"_repolocations.json file containing all inline contents available"
  cat $allPipsMetadata".json" |jq '[.docs[]| {meta : {name: .metadata.name,project:.metadata.project,pipelineid:.metadata.id},stepsJson:.spec.steps,specTemplate:.spec.specTemplate}|select(.stepsJson != {})]' > $allPipsMetadata"_allinline.json"
 
  echo '****** Step 2) generating '$allPipsMetadata"_repolocations.json file containing all repo based pipeline yaml meatadats"
  cat $allPipsMetadata".json" |jq '[.docs[]| {meta : {name: .metadata.name,project:.metadata.project,pipelineid:.metadata.id},stepsJson:.spec.steps,specTemplate:.spec.specTemplate}|select(.specTemplate != null and .stepsJson == {})]' > $allPipsMetadata"_repolocations.json"
 
#   echo '****** Step 3) generating '$allPipsMetadata"_inline.json file containing all inline  pipeline yaml meatadata"
#   cat $allPipsMetadata".json" |jq '[.docs[]| {meta : {name: .metadata.name,project:.metadata.project,pipelineid:.metadata.id},stepsJson:.spec.steps,specTemplate:.spec.specTemplate}|select(.specTemplate == null)]' > $allPipsMetadata"_inline.json"
 
 
  echo "repo metadat retrival completed"
  a=0;




  
  echo "delete a folder by name,cfpips.If you don't wan the script to delete it,please delete it manually "
  rm -r cfpips
  mkdir cfpips


  rm cfcrregistrfinder.log
  rm cfcrregistrfinder.err
  rm $2_pipidentification_Report.csv

   headerrecord="Pipeline ID,Pipeline Name,Step Type ,Step Name , Step Definition"
   echo $headerrecord >> $2_pipidentification_Report.csv

   echo '**** processing inline yamls from repo meta *****'
   a=1
   jq -c '.[]' $allPipsMetadata"_allinline.json" | while read row; do

      #echo $row| jq -c '.stepsJson'

  echo "next row no "$a
  a=`expr $a + 1`

if [ $a -eq 8 ]
then
   echo $row;
fi
#   echo "next row extraction starts"

#   echo  $row | jq -c '.meta.pipelineid'
  pip_id=`echo  $row | jq -c '.meta.pipelineid'|sed 's/\"//g'`
#   echo 'excrted pipid'$pip_id
  pip_name=`echo  $row | jq -c '.meta.name'|sed 's/\"//g'`
#   echo 'excrted pip_name'$pip_name

  build_type_ref=`echo $row|jq '.stepsJson|with_entries( select(.value.type == "build"))'`
  push_cfcr_type_ref=`echo $row|jq '.stepsJson|with_entries( select(.value.registry == "cfcr"))'`

#   echo 'excrted build_type_ref'

      if [ "$build_type_ref" != "{}" ]; then
        echo ' build_type_ref looks good'
                    step_name=`echo $build_type_ref |jq  '.|keys[0]'`
                  
                    JSON_STRING=`echo  $build_type_ref |sed 's/\,/\^/g'`;
                   # echo $JSON_STRING 
                    nextpipoutput=$pip_id","$pip_name",build,"$step_name","$JSON_STRING
                    echo $nextpipoutput >> $2_pipidentification_Report.csv
      else
                    echo "no build step found"$build_type_ref
      fi

      if [ "$push_cfcr_type_ref" != "{}" ]; then
                    step_name=`echo $push_cfcr_type_ref |jq  '.|keys[0]'`
                    JSON_STRING=\'$push_cfcr_type_ref\'
                    echo $JSON_STRING 
                    nextpipoutput=$pip_id","$pip_name",push,"$step_name","$JSON_STRING


                    echo $nextpipoutput >> $2_pipidentification_Report.csv
      else
                   echo $push_cfcr_type_ref
      fi
   done
#    exit 1



   echo "limiting no pip processing to "$3
  jq -c '.[]' $allPipsMetadata"_repolocations.json" | while read row; do

   echo "Processing pipeline no " $a 
   if [ $a -eq $3 ]
   then
      break
   fi
   a=`expr $a + 1`


   repo_loc=`echo  $row | jq -c '.specTemplate.repo'|sed 's/\"//g'`;
   echo 'repo_loc -> '$repo_loc  >> cfcrregistrfinder.log
#             #repo_revision=`echo  $row | jq -c '.specTemplate.revision'`;

    repo_revision=`echo  $row | jq -c '.specTemplate.revision'|sed 's/\"//g'`;
    echo 'repo_revision -> '$repo_revision >> cfcrregistrfinder.log
    

     if [ ${repo_revision}  = "null"  ]; then

                repo_revision="master";

     fi
     repo_revision=`echo  $repo_revision | sed 's/\//%2F/g'`;
     echo 'repo_revision -> '$repo_revision >> cfcrregistrfinder.log

     repo_path=`echo  $row | jq -c '.specTemplate.path'|sed 's/\.//'|sed 's/\///'|sed 's/\"//g'|sed 's/\//%2F/g'`;
     echo 'repo_path' $repo_path >> cfcrregistrfinder.log

     repo_context=`echo  $row | jq -c '.specTemplate.context'|sed 's/\"//g'`;

     repo_url='https://g.codefresh.io/api/repos/'$repo_loc'/'$repo_revision'/'$repo_path'?context='$repo_context
     echo "repo-url --> "$repo_url >> cfcrregistrfinder.log
     pip_id=`echo  $row | jq -c '.meta.pipelineid'|sed 's/\"//g'`
     pip_name=`echo  $row | jq -c '.meta.name'|sed 's/\"//g'`

     echo 'pid id '$pip_id 
     echo 'pid id '$pip_id  >> cfcrregistrfinder.log

     filaname="${repo_loc////_}_$pip_id"


     functionApiCall $repo_url $1 "cfpips/"$filaname".yaml"  false


    #  curl -X GET $repo_url \
    #                 -H 'x-access-token: '$accessToken  > "cfpips/"$filaname".yaml" 
                   # $repo_url  > "cfpips/"$filaname".yaml"
      sleep 1
      rm fil1.yaml
      cp "cfpips/"$filaname".yaml" fil1.yaml
      repo_yaml=`yq -j r fil1.yaml| jq '.| {spec:.steps}|.[]' > "cfpips/"$filaname".json"`
      f="cfpips/"$filaname".json"
      if [[ -s $f ]]; then 
        #  echo "file has something"; 
            firstline=`tail -1 $f`
            echo "firstline" $firstline  >> cfcrregistrfinder.log
            if [ "$firstline" != "null" ]; then
               
                #echo 'next json file '$f ',cfcr references --> '`cat $f |jq '.|with_entries( select(.value.type == "build" or .value.registry == "cfcr" ))'`;
                build_type_ref=`cat $f |jq '.|with_entries( select(.value.type == "build"))'`
                push_cfcr_type_ref=`cat $f |jq '.|with_entries( select(.value.registry == "cfcr"))'`
                

                if [ "$build_type_ref" != "{}" ]; then
                    step_name=`echo $build_type_ref |jq  '.|keys[0]'`
                  
                    JSON_STRING=`echo  $build_type_ref |sed 's/\,/\^/g'`;
                   # echo $JSON_STRING 
                    nextpipoutput=$pip_id","$pip_name",build,"$step_name","$JSON_STRING
                    echo $nextpipoutput >> $2_pipidentification_Report.csv
                else
                    echo $build_type_ref
                fi

                 
                if [ "$push_cfcr_type_ref" != "{}" ]; then
                    step_name=`echo $push_cfcr_type_ref |jq  '.|keys[0]'`
                    JSON_STRING=\'$push_cfcr_type_ref\'
                    echo $JSON_STRING 
                    nextpipoutput=$pip_id","$pip_name",push,"$step_name","$JSON_STRING


                    echo $nextpipoutput >> $2_pipidentification_Report.csv
                else
                   echo $push_cfcr_type_ref
                fi
               


            else
             
                echo "invalid json in $f"  >> cfcrregistrfinder.err
                echo "repo-url --> "$repo_url >> cfcrregistrfinder.err
                head -5 fil1.yaml >>  cfcrregistrfinder.err
                echo "" >>  cfcrregistrfinder.err

            fi
      else 
            echo "file : $f is empty";  >> cfcrregistrfinder.err
            echo "repo-url --> "$repo_url >> cfcrregistrfinder.err
            head -5 fil1.yaml >>  cfcrregistrfinder.err
            echo "" >>  cfcrregistrfinder.err

      fi







  done


}




function1 $1 $2 $3


}













