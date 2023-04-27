FROM node

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 80

ENV MONGODB_PORT=27017

CMD ["npm", "start"]