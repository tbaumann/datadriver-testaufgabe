FROM node:23
EXPOSE 8000/tcp
HEALTHCHECK CMD curl -f http://localhost:8000/live || exit 1

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install

COPY . .
CMD ["node", "app.js"]
