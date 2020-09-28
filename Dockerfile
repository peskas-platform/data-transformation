FROM rocker/r-ver:4.0.2 AS prod

RUN install2.r googleCloudRunner plumber bigrquery janitor

COPY . /home
WORKDIR /home

ENTRYPOINT ["R", "-e", "pr <- plumber::plumb('api.R'); pr$run(host='0.0.0.0', port=as.numeric(Sys.getenv('PORT')))"]
CMD ["api.R"]
