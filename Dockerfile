FROM node:lts-bullseye-slim
WORKDIR /app
COPY package*.json tsconfig*.json nest-cli.json ./
RUN npm install
COPY . .
ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1
EXPOSE 3000
CMD ["npm", "start"]
