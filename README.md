# cfcf migration - pipeline identification

This is a sample node.js based script to find all pipelines under a codefresh account impacted by  codefresh integreted registry, cfcr deprectation.

More about CFCR registry depreaction - https://codefresh.io/docs/docs/docker-registries/cfcr-deprecation/

## script logic

This script identifies the various pipelines in the following order.

1. Find metadata for all pipelines under an account using the restapi.

2. Breakdown metada into 2 buckets
     2.1 Inline Pipelines Spec metada
     2.2 Pipelines with step definition stored as part of last build.
     
3. Inspect all the inline steps for the following steps types.
 
     3.1 build steps using codefresh  type:build
     
     3.2 push steps using codefresh type:push and registry:'cfcr'
     
     3.3 pull steps using image registry containing 'r.cfcr.io/*'
     
     collect the pipeline and steps details of those pipelines matching 3.1, 3.2 and 3.3 criteria into an output csv report file.
     
4. Inspect those pipelines, not having inline steps definiton but  the yaml stored in a last build..
    
      4.1 Retreive the pipeline definion from the last build and convert into a json format.
      
      4.2 build steps using codefresh type:build
     
      4.3 push steps using codefresh type:push and registry:'crcf'
      
      4.4 pull steps using image registry containing 'r.cfcr.io/*'
     
     collect the pipeline and steps details of those pipelines fulfilling the 4.2,4.3 and 4.4 into an output csv report file.
      
    

### How to run the script

You can run this script as a node js script using node cli, passing the codefresh account API key as an env value by keeping it in .env file.

To run this script install node.js and then run as follows


```
./node CFCRpipidentifier.js
```
  A dcoker image available which you can run and generate the output, if you don'nt wnat install and run the nodejs 

How to Run | parameters | parameter description
------------ | -------------
1. using prebuilt docer image | Content from cell 2
mkdir ~/cfoutput
docker run -e APIKEY="yourAPIkeyhere" -v ~/cfoutput:/output cfcrregpips:latest |APIKEY ,~/cfoutput | APIKEY - Your account APIKey , ~/cfoutput your host machine folder mounted to docer porcess to generate the output files.

2. ./node CFCRpipidentifier.js | apikey | account acpi key

### Output

Script will generate a run log and a csv file report of the pieplines that need to be changed under /output folder. The output folder can be changed by passing a differetn fodler path through outputfolder enviroment variable.

Output files produced are 

E.g 
```
cfcrmigrationpipelines.csv
run_log.log

```

