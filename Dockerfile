#### base ####
FROM node:16-bullseye-slim as base
ENV NODE_ENV=production
# Avoid running nodejs process as PID 1
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    tini \
    && rm -rf /var/lib/apt/lists/*
EXPOSE 3000
RUN mkdir /app && chown -R node:node /app
WORKDIR /app
USER node
COPY --chown=node:node package*.json ./
RUN npm ci --only=production && npm cache clean --force

#### dev ####
# no source to be added, and assumes bind mount
FROM base as dev
ENV NODE_ENV=development
ENV PATH=/app/node_modules/.bin:$PATH
RUN npm install --only=development && npm cache clean --force
CMD ["nodemon", "index.js"]

#### source ####
FROM base as source
# copy source code
COPY --chown=node:node . .

#### test ####
FROM source as test
ENV NODE_ENV=development
ENV PATH=/app/node_modules/.bin:$PATH
COPY --from=dev /app/node_modules /app/node_modules
# RUN npx eslint .
RUN npm test
CMD ["npm", "run", "test"]

#### prod ####
FROM source as prod
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "index.js"]
