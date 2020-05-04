
require('dotenv').config()

const API_KEY = process.env.APIKEY;


if (process.env.APIKEY) {
    process.env.APIKEY = process.env.APIKEY.substring(process.env.APIKEY.length - 5);

}

console.log("Your env values", process.env)

if (!process.env.APIKEY && !process.env.XACCESSTOKEN) {

    console.log("Need to pass your Codefresh account APIKEY as an enviorment variable ");
    process.exit(1);
}

const outputfolder = process.env.outputfolder || './output'

console.log("outputfolder -->", outputfolder)
const Logger = require('./winstonlogger')

const logger = new Logger.CSVLogger(outputfolder);
const reglogger = new Logger.RegLogger(outputfolder);



reglogger.info("this node.js program will identify and genrate a CSV report of all the pipelines under your accout \n\n usage  npm install\n edit .env and add your account API key \n node CFCRpipidentifier ");


const fs = require('fs');

const _ = require('underscore');
const yaml = require('js-yaml');


const API_KEY_VS_TOKEN = process.env.key_vs_token || "true"

if (process.env.APIKEY && API_KEY_VS_TOKEN === 'true') {
    const APIKEYlog = process.env.APIKEY.substring(process.env.APIKEY.length - 5);
    reglogger.info('APIKEY -> ***' + APIKEYlog);
}
if (process.env.XACCESSTOKEN) {
    const APIACCESSTOKENlog = process.env.XACCESSTOKEN.substring(process.env.XACCESSTOKEN.length - 5);

    reglogger.info('AcceToken -> ****' + APIACCESSTOKENlog);
}

const axios = require('axios');

let rootUrl = "https://g.codefresh.io/api/";

//+ process.env.CF_BASE_URL || '

let allPipsMeta = "pipelines?includeBuilds=false&limit=1000&offset=0";
let piplineReportsG = []

const fsp = require('fs').promises;

// This must run inside a function marked `async`:
//const file = await fs.readFile('cfcrmigrationpipelines.csv', 'utf8');
const CSV_FILENAME = "cfcrmigrationpipelines.csv";
const metaretriever = async () => {

    try {


        // backup current csv report


        // axios({
        //     method: 'get',
        //     url: allPipsMeta,
        //     baseURL: process.env.CF_BASE_URL,
        //     headers: { 'x-access-token': process.env.XACCESSTOKEN },
        // });
        let resourcePath = "pipelines?includeBuilds=false&limit=1000&offset=0"
        let allPipsMetadata = await callcodefreshapis(resourcePath);

        if (allPipsMetadata.status === 200) {

            reglogger.info("successfullly  retirieved the all pipelines metadata ");

            reglogger.info("Total pipelines under this account : ", allPipsMetadata.data.count);
        } else {
            console.error("failed to  retirieved the all pipelines metadata " + allPipsMetadata.status);

            reglogger.info(JSON.stringify(allPipsMetadata));
        }


        // next get each pipeline build and csv ...
        let pullcount = 0;
        let pushcount = 0;
        let piplineReports = []
        let piplineReportsA = []
        let piplineReportsB = []

        _.forEach(allPipsMetadata.data.docs, async function (nextitem, index) {


            //  reglogger.info(nextitem.metadata.id, " ", nextitem.metadata.name);

            let metadata = nextitem.metadata; // pipeline metadata
            let pilinesteps = nextitem.spec.steps; // pipeline steps, can ebe null

            let pilinestepNames = _.keys(pilinesteps);

            // reglogger.info(pilinestepNames)
            if (pilinestepNames.length > 0) // pipeline steps exists
            {


                await processStespForCFCR(metadata.id, metadata.name, pilinesteps, pilinestepNames, piplineReports)

            } else {

                // if you can get the last build id, you cna get the dbuild as https://g.codefresh.io/api/builds/5eaa186bfbe1ee6180c6add6

                // reglogger.info(`Inline pipeline definition not avaialble for the pipeline ${nextitem.metadata.id} : ${nextitem.metadata.name} . Need to go after the repo and pull the yml`)

                resourcePath = "workflow/?limit=1&page=1&pageSize=1&pipeline=" + nextitem.metadata.id;

                // reglogger.info(resourcePath)
                let pipFromLastBuild = await callcodefreshapis(resourcePath);
                if (pipFromLastBuild.status === 200) {

                    //  reglogger.info("successfullly  retirieved the pipeline last build data ");

                    //  reglogger.info("build metadata : ", JSON.stringify(pipFromLastBuild.data));

                    if (pipFromLastBuild.data.workflows.total >= 1) {
                        let pipFinalYaml = pipFromLastBuild.data.workflows.docs[0];

                        if (pipFinalYaml.finalWorkflowYaml != undefined) {
                            pilinesteps = await getBuildYamlAsJson(pipFinalYaml.finalWorkflowYaml);

                            //if("5cca0b91f830305f89308412" === metadata.id)
                            // reglogger.info("pipjson", JSON.stringify(pilinesteps));

                            pilinesteps = pilinesteps.steps;
                            pilinestepNames = _.keys(pilinesteps);
                            await processStespForCFCR(metadata.id, metadata.name, pilinesteps, pilinestepNames, piplineReports);


                        } else if (pipFinalYaml.userYamlDescriptor != undefined) {

                            pilinesteps = await getBuildYamlAsJson(pipFinalYaml.userYamlDescriptor);

                            //if("5cca0b91f830305f89308412" === metadata.id)
                            // reglogger.info("pipjson", JSON.stringify(pilinesteps));

                            pilinesteps = pilinesteps.steps;
                            pilinestepNames = _.keys(pilinesteps);
                            await processStespForCFCR(metadata.id, metadata.name, pilinesteps, pilinestepNames, piplineReports);



                        }
                        else {

                            // reglogger.info(`Inline pipeline definition not avaialble for the pipeline ${nextitem.metadata.id} : ${nextitem.metadata.name} . Need to go after the repo and pull the yml does not have any builds run so not finalYaml`)
                            reglogger.info(`\n\n Pipeline definition not available through inline or from a last build. Need to go after the repo for this pipeline. ${nextitem.metadata.id} : ${nextitem.metadata.name} \n\n`);
                        }
                    } else {

                    }



                    // return true;
                } else {
                    console.error("failed to  retirieved the all pipelines metadata no" + allPipsMetadata.status);

                    reglogger.info(JSON.stringify(allPipsMetadata));
                }

            }
        })





    } catch (err) {


        reglogger.info(err);
    }

}

metaretriever();

reglogger.info("done");


const test1 = async () => {

    let testResp = await callcodefreshapis('builds/5bb66dce31dfce595fccbb7e')

    if (testResp.status === 200) {

        reglogger.info("successfullly  retirieved the all pipelines metadata ");

        reglogger.info(JSON.stringify(testResp.data)
        )

        var myJSONString = testResp.data.finalWorkflowYaml;
        var myEscapedJSONString = myJSONString.replace(/\\n/g, "\\n")
            .replace(/\\'/g, "\\'")
            .replace(/\\"/g, '\\"')
            .replace(/\\&/g, "\\&")
            .replace(/\\r/g, "\\r")
            .replace(/\\t/g, "\\t")
            .replace(/\\b/g, "\\b")
            .replace(/\\f/g, "\\f");

        yaml = require('js-yaml');
        try {
            var doc = yaml.safeLoad(myEscapedJSONString);
            reglogger.info(doc);
        } catch (e) {
            reglogger.info(e);
        }

        //reglogger.info(myEscapedJSONString);

        // reglogger.info("Total pipelines under this account : ", JSONString);
    } else {
        console.error("failed to  retirieved the all pipelines metadata " + testResp.status);

        reglogger.info(JSON.stringify(testResp));
    }
}

const test2 = async () => {

    reglogger.info("test2");

    fs.readFile('test1.json', (err, data) => {
        if (err) throw err;
        let metta = JSON.parse(data);
        reglogger.info(metta);
    });


}

//test1();

async function getBuildYamlAsJson(yamlString) {
    var escapedYamlString = yamlString.replace(/\\n/g, "\\n")
        .replace(/\\'/g, "\\'")
        .replace(/\\"/g, '\\"')
        .replace(/\\&/g, "\\&")
        .replace(/\\r/g, "\\r")
        .replace(/\\t/g, "\\t")
        .replace(/\\b/g, "\\b")
        .replace(/\\f/g, "\\f");
    try {
        var doc = yaml.safeLoad(escapedYamlString);
        // reglogger.info(doc);
        return doc;
    } catch (e) {
        reglogger.info(e);
        throw e;
    }
}

//test1();


async function processStespForCFCR(mid, mname, pilinesteps, pilinestepNames, piplineReports) {

    let pullcount = 0;
    let pushcount = 0;
    _.forEach(pilinestepNames, function (nextpipstep, index) {

        // reglogger.info("  ", nextpipstep);

        let pipStepCode = _.keys(pilinesteps[nextpipstep]);

        _.forEach(pipStepCode, async function (nextStepCode, index) {


            let pipvalue = _.propertyOf(pilinesteps)(nextpipstep);
            let stepvalue = _.propertyOf(pipvalue)(nextStepCode);


            // reglogger.info("          ", nextStepCode, ": ", stepvalue);



            if (stepvalue != undefined) {
                //reglogger.info("          ", nextStepCode, ": ", stepvalue);
                let matchedItem = "";
                if ((typeof stepvalue === 'string') || (stepvalue instanceof String))

                    if (stepvalue.includes('r.cfcr.io')) {
                        //     reglogger.info(nextitem.meta.pipelineid, " ", nextitem.meta.name);
                        //     reglogger.info("  ", nextpipstep);
                        // reglogger.info("          ", nextStepCode, ": ", stepvalue);
                        pullcount = pullcount + 1
                        //PipelineID,PipelineName,Step type,StepName
                        matchedItem = mid + "," + mname + ",pull, " + nextpipstep
                        logger.info(matchedItem);
                        piplineReportsG.push(matchedItem)
                        // writenewreocrd(matchedItem);
                        //     reglogger.info(nextitem.meta.name, " contains a step using cfcr ")

                    } else if (stepvalue === 'cfcr') {

                        //     // reglogger.info(nextitem.meta.name , " no cfcr ", )
                        pushcount = pushcount + 1
                        //PipelineID,PipelineName,Step type,StepName
                        matchedItem = mid + "," + mname + ",push, " + nextpipstep
                        logger.info(matchedItem);
                        piplineReportsG.push(matchedItem)
                        // writenewreocrd(matchedItem);
                    } else if (stepvalue === 'build' && nextStepCode === 'type') {

                        if ("5e9e1839580e7a48ffb0df1a" === mid) {

                            reglogger.info("nextStepCode ", nextStepCode);
                        }

                        matchedItem = mid + "," + mname + ",build, " + nextpipstep
                        logger.info(matchedItem);
                        piplineReportsG.push(matchedItem)
                        // writenewreocrd(matchedItem);

                    }

            } else {

                let pipvalue = _.propertyOf(pilinesteps)(nextpipstep);
                let stepvalue = _.propertyOf(pipvalue)(nextStepCode);

                reglogger.info(pipvalue)
                reglogger.info("nextpipstep", nextpipstep, "nextStepCode ", nextStepCode)

            }

        })

        // reglogger.info("done processing the next step --> ", index)
    })

}

async function writenewreocrd(record) {

    try {
        fs.appendFileSync(CSV_FILENAME, record);
        //  reglogger.info('The "data to append" was appended to file!');
    } catch (err) {
        /* Handle the error */

        reglogger.info("data append to file error ", err)
    }



}

async function callcodefreshapis(resourcePath) {

    reglogger.info(`Inoking codefresh api for the resource ${resourcePath}`)

    let config = {
        headers: { 'x-access-token': process.env.XACCESSTOKEN },
        params: {

        },
    }

    //console.log("API_KEY_VS_TOKEN ",API_KEY_VS_TOKEN);
    if (API_KEY_VS_TOKEN === 'true') {

        //console.log("API key passed ", process.env.APIKEY);
        config.headers = { 'Authorization': API_KEY }
    }

    //reglogger.info(process.env.CF_BASE_URL + resourcePath)

    //console.log("config ",JSON.stringify(config))
    const cfAPIResponse = await axios.get(rootUrl + resourcePath, config)
    return cfAPIResponse;

}

