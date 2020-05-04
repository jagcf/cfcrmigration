const winston = require('winston')



const CSV_FILENAME = "cfcrmigrationpipelines.csv";
const fs = require('fs');

dateFormat = () => {
  return new Date(Date.now()).toUTCString()
}



class LoggerService {
  // outputfolder='.'
  constructor(outputfolder) {

    try {
      console.log("outputfolder-->",outputfolder);
      fs.rename(outputfolder+CSV_FILENAME, outputfolder+"prev_cfcrmigrationpipelines.csv", (err) => {
        // if (err) throw err;
        console.log(`current csv fle renamed to ${outputfolder}/prev_cfcrmigrationpipelines.csv`);
      });
    } catch (err) {
     console.log("current csv fle rename error.May not exists yet");
    }

    const logger = winston.createLogger({
      transports: [
        // new winston.transports.Console(),
        new winston.transports.File({
          filename: `${outputfolder}/cfcrmigrationpipelines.csv`
        })
      ],
      format: winston.format.printf((info) => {

        // // let message = `${dateFormat()} | ${info.level.toUpperCase()} | ${route}.log | ${info.message} | `
        // message = info.pipid+","
        // let message = info.obj ? `${JSON.stringify(info.obj)} | ` : "notvalidcsv"
        // // message = this.log_data ? message + `log_data:${JSON.stringify(this.log_data)} | ` : message
        // //let message = `${info.a},${info.a}`


        return info.message
      })
    });
    this.logger = logger
  }

  async info(message) {
    this.logger.log('info', message);
  }
  async info(message, obj) {
    this.logger.log('info', message, {
      obj
    })
  }

}

class RegLogger {

  constructor(outputfolder) {
   try {
      fs.rename(outputfolder+"/current_run_log.log", outputfolder+"/prev_run_log.log", (err) => {
        // if (err) throw err;
        console.log(`current run log file backed to ${outputfolder}/prev_run_log.log`);
      });
    } catch (err) {


                 console.log("run log fle rename error.May not exists yet")
    }

    const logger = winston.createLogger({
      transports: [
        new winston.transports.Console(),
        new winston.transports.File({
          filename: `${outputfolder}/run_log.log`
        })
      ],
      format: winston.format.printf((info) => {


        let message = `${dateFormat()} | ${info.level.toUpperCase()}  ${info.message} | `
        message = info.obj ? message + `data:${JSON.stringify(info.obj)} | ` : message
        // message = this.log_data ? message + `log_data:${JSON.stringify(this.log_data)} | ` : message
        return message



      })
    });
    this.logger = logger
  }

  async info(message) {
    this.logger.log('info', message);
  }
  async info(message, obj) {
    this.logger.log('info', message, {
      obj
    })
  }
  async debug(message) {
    this.logger.log('debug', message);
  }
  async debug(message, obj) {
    this.logger.log('debug', message, {
      obj
    })
  }
  async error(message) {
    this.logger.log('error', message);
  }
  async error(message, obj) {
    this.logger.log('error', message, {
      obj
    })
  }


}

module.exports = {
  CSVLogger: LoggerService,
  RegLogger: RegLogger
}
