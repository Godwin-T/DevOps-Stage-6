FROM node:18-bullseye AS base
WORKDIR /usr/src/app

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

EXPOSE 8082
ENV TODO_API_PORT=8082
CMD ["npm", "start"]
