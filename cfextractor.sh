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

function1 ()  {

      echo "starting retrieveing all repo urls"

      rm cfcrregistrfinder_step2.log
      rm cfcrregistrfinder_stpe2.err
      rm -r cfpips
      mkdir cfpips

      //get all the pipeline ids
      pipsMetaUrl="https://g.codefresh.io/api/pipelines?limit=200&offset=0"
      allPipsMetadata="cfpips/"$2"_allPipsMetadata"

      echo '****** Step .1) Invoking '$pipsMetaUrl' to collect all pipelines detailed metadata into a file '$allPipsMetadata"All.json"
      #rm cfpips/$allPipsMetadata".json"
      functionApiCall $pipsMetaUrl $1 $allPipsMetadata"All.json" true


      echo '****** Step 1) generating '$allPipsMetadata"_metadata.json file containing only pipeline metadata available"

      cat $allPipsMetadata"All.json" |jq '[.docs[]| {meta : {name: .metadata.name,project:.metadata.project,pipelineid:.metadata.id}}]' > $allPipsMetadata"_metadata.json"
 
     # get the last build per pipeline

      echo '****** Step 2) generating '$allPipsMetadata"_metadata.json file containing only pipeline metadata available"

      #cat $allPipsMetadata".json" |jq '[.docs[]| {meta : {name: .metadata.name,project:.metadata.project,pipelineid:.metadata.id}}]' > $allPipsMetadata"_metadat.json"
      a=1
      jq -c '.[]' $allPipsMetadata"_metadata.json" | while read row; do
        pip_id=`echo  $row | jq -c '.meta.pipelineid'|sed 's/\"//g'`
        #   echo 'excrted pipid'$pip_id
        pip_name=`echo  $row | jq -c '.meta.name'|sed 's/\"//g'`
        
        if [ $a -eq 250 ]
        then
          echo "processing pipline no" $a  "pipelin id " $pip_id " name : " $pip_name " and breaking the loop"
          break
        #     
        fi
        a=`expr $a + 1`;


        pipBuildUrl="https://g.codefresh.io/api/workflow/?limit=1&page=1&pageSize=1&pipeline="$pip_id
        filaname="${pip_name////_}_$pip_id"
        mfilename="cfpips/"$filaname"_meta.json"
        functionApiCall $pipBuildUrl $1 $mfilename true
        finalWorkflowYaml=$(cat $mfilename| jq '.workflows.docs[0].finalWorkflowYaml' | sed 's/\\n/\'$'\n''/g' | sed -e 's/^"//' -e 's/"$//')
        #echo "$finalWorkflowYaml"   
        yfilename="cfpips/"$filaname".yaml"
        echo "$finalWorkflowYaml" > $yfilename
        $(yq -j r $yfilename| jq '.| {spec:.steps}|.[]' > "cfpips/"$filaname".json")
      done
     echo "processed " $a  " no of pipelines from the metadata repsong into the folder cfpips"
       

}


function2(){


  a=1
  rm cfcrregistrfinder_step2.log
  rm cfcrregistrfinder_stpe2.err
  rm $2_pipidentification_Report.csv
  allPipsMetadata=$2"_allPipsMetadata"
  a=1
  cat cfpips/$allPipsMetadata"_metadata.json"|jq -c '.[]'| while read row; do
    
    pip_id=`echo  $row | jq -c '.meta.pipelineid'|sed 's/\"//g'`
        #   echo 'excrted pipid'$pip_id
    pip_name=`echo  $row | jq -c '.meta.name'|sed 's/\"//g'`
    if [ $a -eq 250 ]
        then
          #echo "processing pipline no" $row  "pipelin id " $pip_id " name : " $pip_name
          break
    else 
         echo "processing pipline no "$a" pipelin id: " $pip_id ", name : " $pip_name
         
    fi
     a=`expr $a + 1`;
    filaname="${pip_name////_}_$pip_id"

    f="cfpips/"$filaname".json"
    if [[ -s $f ]]; then 
        #  echo "file has something"; 
            firstline=`tail -1 $f`
            echo "firstline" $firstline  >> cfcrregistrfinder_step2.log
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
                    echo 'no type:build in pipeline '$pip_name >> cfcrregistrfinder_step2.log
                fi

                 
                if [ "$push_cfcr_type_ref" != "{}" ]; then
                    step_name=`echo $push_cfcr_type_ref |jq  '.|keys[0]'`
                    JSON_STRING=\'$push_cfcr_type_ref\'
                    echo $JSON_STRING 
                    nextpipoutput=$pip_id","$pip_name",push,"$step_name","$JSON_STRING


                    echo $nextpipoutput >> $2_pipidentification_Report.csv
                else
                   echo 'no push:type registry:cfcr in pipeline '$pip_name >> cfcrregistrfinder_step2.log
                fi


                cfcrrep=$(cat $f|grep -o '"r.cfcr.io/[^ ]*\"'|sed 's/\"//g'|head -1)

                if [ ! -z "$cfcrrep" ]; then 
                    echo $pip_name' contains... reference to a r.cfcr.io image '$cfcrrep  #>> cfcrregistrfinder_step2.log

                    
                    pull_cfcr_type_ref=`cat $f |jq --arg cfcrref $cfcrrep '.|with_entries( select(.value.image == $cfcrref))'`

                   # echo $pull_cfcr_type_ref
                
                    if [ "$pull_cfcr_type_ref" != "{}" ]; then
                        step_name=`echo $pull_cfcr_type_ref |jq  '.|keys[0]'`
                        JSON_STRING=\'$pull_cfcr_type_ref\'
                        #echo $JSON_STRING 
                        nextpipoutput=$pip_id","$pip_name",pull,"$step_name","$JSON_STRING
                        echo $nextpipoutput >> $2_pipidentification_Report.csv
                    else
                    #echo 'no push:type registry:cfcr in pipeline '$pip_name >> cfcrregistrfinder_step2.log
                        
                        pull_cfcr_pip=`cat $f |jq '.'`
                        nextpipoutput=$pip_id","$pip_name",pull,step_error,"$pull_cfcr_pip
                        echo $nextpipoutput >> $2_pipidentification_Report.csv
                    fi
                else
                   echo $pip_name' does not contains reference to a r.cfcr.io image '$cfcrrep  >> cfcrregistrfinder_step2.log

                fi


            else
             
                echo "invalid json in $f"  >> cfcrregistrfinder_stpe2.err
               
               # head -5 fil1.yaml >>  cfcrregistrfinder_stpe2.err
                echo "" >>  cfcrregistrfinder_stpe2.err

            fi
      else 
            echo "file : $f is empty";  >> cfcrregistrfinder_stpe2.err
           # head -5 fil1.yaml >>  cfcrregistrfinder_stpe2.err
            echo "" >>  cfcrregistrfinder_stpe2.err

    fi


  done

}
# process all json files for the build, push , pull patterns


if [ $# -eq 3 ]; then
   # echo "Your command line contains $# arguments"
  
    # prepare data content. Metadata, yaml and json files for a pipeline
    function1 $1 $2 $3
    # run regex against the pipeline to identify the changes
    
    function2 $1 $2 $3
  #  function3 $1 $2 $3
else    
   echo "please run the script passing our codefresh api key as ./cfbuld.sh <api_key> account_shorthandname pipelin limit"
fi
















