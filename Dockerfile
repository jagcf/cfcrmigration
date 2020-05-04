FROM node:10-alpine


# ENV WAIT_VERSION 2.7.3
# ADD https://github.com/ufoscout/docker-compose-wait/releases/download/$WAIT_VERSION/wait /wait
# RUN chmod +x /wait

RUN mkdir -p /home/node/app/node_modules && chown -R node:node /home/node/app

WORKDIR /home/node/app
# RUN  groupadd redis
COPY package.json ./package.json

#RUN rm -rf ./app
#RUN rm -rf ./keys

#COPY app/mocks/acvalues.json ./
#COPY output ./output

COPY CFCRpipIdentifier.js ./
COPY winstonlogger.js ./

RUN ls -ltr
RUN cat package.json
#RUN cat .env

USER node

RUN npm install

COPY --chown=node:node . .




#EXPOSE 3000

CMD [ "node", "CFCRpipIdentifier.js" ]