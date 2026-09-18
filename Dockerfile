FROM node:22.23.2-alpine3.24

WORKDIR /app

COPY package*.json ./

RUN npm install -g npm@12 && npm ci

COPY src ./src

EXPOSE 3000

CMD ["npm", "start"]