# cfcf migration - pipeline identification

This is sample script to find the pipelines impacted by the codefresh integreted registry, cfcr deprectation.

More about CFCR registry decomssionsing - https://codefresh.io/docs/docs/docker-registries/cfcr-deprecation/

## script logic

This script identifies the various pipelins in the following order.

1. Find metadata for all pipelines under an account using the restapi.

2. Breakdown metada into 2 buckets
     2.1 Inline Pipeline Spec metada
     2.2 Pipelines with step definition in a repo.
     
3. Inspect all the inline steps for the following steps types.
 
     3.1 build steps using codefresh type:build
     
     3.2 push types using codefresh type:push and registry:'crcf'
     
     collect the pipeline and steps details of those pipelines fulfilling the 3.1 and 3.2 into an output csv report file.
     
4. Inspect those pipelines, not having inline steps definiton and the yaml stored in a repo..
    
      4.1 Retreive the pipeline definion from the repo and convert into a json format.
      
      4.2 build steps using codefresh type:build
     
      4.3 push types using codefresh type:push and registry:'crcf'
     
     collect the pipeline and steps details of those pipelines fulfilling the 3.1 and 3.2 into an output csv report file.
      
    

### How to run the script

You can run the script passing the codefresh account API key, shorthand for your account name  and the limit to restrict the no of repo pipeline to process.

E.g 

```
./cfextractor.sh api-key cfdemo 10
```

### Output

Script will generate a number pipeline files into a directory by name cfpips.

Along with an execution log and errlog files, the key file that you should look out for is an output csv file containing the report of all the impacted pieplines.

E.g 
```
cfdemo_pipidentification_Report.csv
```

