# cfcf migration - pipeline identification

This is a sample script to find all pipelines under a codefresh account impacted by  codefresh integreted registry, cfcr deprectation.

More about CFCR registry depreaction - https://codefresh.io/docs/docs/docker-registries/cfcr-deprecation/

## script logic

This script identifies the various pipelines in the following order.

1. Find metadata for all pipelines under an account using the restapi.

2. Breakdown metada into 2 buckets
     2.1 Inline Pipelines Spec metada
     2.2 Pipelines with step definition stored in a repo.
     
3. Inspect all the inline steps for the following steps types.
 
     3.1 build steps using codefresh  type:build
     
     3.2 push steps using codefresh type:push and registry:'cfcr'
     
     3.3 pull steps using image registry containing 'r.cfcr.io/*'
     
     collect the pipeline and steps details of those pipelines matching 3.1, 3.2 and 3.3 criteria into an output csv report file.
     
4. Inspect those pipelines, not having inline steps definiton but  the yaml stored in a repo..
    
      4.1 Retreive the pipeline definion from the repo and convert into a json format.
      
      4.2 build steps using codefresh type:build
     
      4.3 push steps using codefresh type:push and registry:'crcf'
      
      4.4 pull steps using image registry containing 'r.cfcr.io/*'
     
     collect the pipeline and steps details of those pipelines fulfilling the 4.2,4.3 and 4.4 into an output csv report file.
      
    

### How to run the script

You can run the script passing the codefresh account API key, shorthand for your account name  and the limit to restrict the no of repo pipeline to process.

E.g 

```
./cfextractor.sh api-key cfdemo 10
```

### Output

Script will generate a number pipeline spec files into a directory by name cfpips.

Along with an execution log and err log files, the important report file that you should look out for is an output csv file containing all the impacted pieplines.

E.g 
```
cfdemo_pipidentification_Report.csv
```

