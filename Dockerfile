FROM node:16-bullseye-slim AS build
WORKDIR /app
COPY ["package.json", "package-lock.json*", "./app"]
RUN npm ci

FROM gcr.io/distroless/nodejs:16
COPY --from=build /app /app
WORKDIR /app
CMD [ "node", "./bin/www" ]

#FROM node
#ENV NODE_ENV=development
#WORKDIR /app
#COPY ["package.json", "package-lock.json*", "./"]
#RUN npm ci
#COPY . .
#CMD [ "node", "./bin/www" ]
