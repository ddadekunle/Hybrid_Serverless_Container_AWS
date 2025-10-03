FROM node:20-alpine

workdir /app

COPY package*.json ./
RUN npm ci --only=production

copy src ./src

EXPOSE 8080

CMD ["node", "src/index.js"]