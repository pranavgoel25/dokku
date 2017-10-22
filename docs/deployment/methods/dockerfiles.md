# Dockerfile Deployment

> New as of 0.3.15

While Dokku normally defaults to using [heroku buildpacks](https://devcenter.heroku.com/articles/buildpacks) for deployment, you can also use docker's native `Dockerfile` system to define a container.

> Dockerfile support is considered a **Power User** feature. By using Dockerfile-based deployment, you agree that you will not have the same comfort as that enjoyed by Buildpack users, and Dokku features may work differently. Differences between the two systems will be documented here.

To use a dockerfiles for deployment, commit a valid `Dockerfile` to the root of your repository and push the repository to your Dokku installation. If this file is detected, Dokku will default to using it to construct containers **except** in the following two cases:

- The application has a `BUILDPACK_URL` environment variable set via the `dokku config:set` command or in a committed `.env` file. In this case, Dokku will use your specified buildpack.
- The application has a `.buildpacks` file in the root of the repository. In this case, Dokku will use your specified buildpack(s).

## Exposed ports

> Changed as of 0.5.0

Dokku will extract all tcp ports exposed using the `EXPOSE` directive (one port per line) and setup nginx to proxy the same port numbers to listen publicly. If you would like to change the exposed port, you should do so within your `Dockerfile` and app.

> Note: Nginx does not support proxying UDP. UDP ports can be exposed by disabling the nginx proxy with `dokku proxy:disable myapp`

If you do not explicitly `EXPOSE` a port in your `Dockerfile`, Dokku will configure the nginx proxy to listen on port 80 (and 443 for TLS) and forward traffic to your app listening on port 5000 inside the container. Just like buildpack apps, you can also use the `$PORT` environment variable in your app to maintain portability.

When ports are exposed through the default nginx proxy, they are proxied externally as HTTP ports. At this time, in no case do we proxy plain TCP or UDP ports. If you would like to investigate alternative proxy methods, please refer to our [proxy management documentation](/dokku/advanced-usage/proxy-management/).

## Customizing the run command

By default no arguments are passed to `docker run` when deploying the container and the `CMD` or `ENTRYPOINT` defined in the `Dockerfile` are executed. You can take advantage of docker ability of overriding the `CMD` or passing parameters to your `ENTRYPOINT` setting `$DOKKU_DOCKERFILE_START_CMD`. Let's say for example you are deploying a base nodejs image, with the following `ENTRYPOINT`:

```Dockerfile
ENTRYPOINT ["node"]
```

You can do:

```shell
dokku config:set APP DOKKU_DOCKERFILE_START_CMD="--harmony server.js"
```

To tell docker what to run.

Setting `$DOKKU_DOCKERFILE_CACHE_BUILD` to `true` or `false` will enable or disable docker's image layer cache. Lastly, for more granular build control, you may also pass any `docker build` option to `docker`, by setting `$DOKKU_DOCKER_BUILD_OPTS`.

### Procfiles and Multiple Processes

> New as of 0.5.0

You can also customize the run command using a `Procfile`, much like you would on Heroku or
with a buildpack deployed app. The `Procfile` should contain one or more lines defining [process
types and associated commands](https://devcenter.heroku.com/articles/procfile#declaring-process-types).
When you deploy your app a Docker image will be built, the `Procfile` will be extracted from the image
(it must be in the folder defined in your `Dockerfile` as `WORKDIR` or `/app`) and the commands
in it will be passed to `docker run` to start your process(es). Here's an example `Procfile`:

```Procfile
web: bin/run-prod.sh
worker: bin/run-worker.sh
```

And `Dockerfile`:

```Dockerfile
FROM debian:jessie
WORKDIR /app
COPY . ./
CMD ["bin/run-dev.sh"]
```

When you deploy this app the `web` process will automatically be scaled to 1 and your Docker container
will be started basically using the command `docker run bin/run-prod.sh`. If you want to also run
a worker container for this app, you can run `dokku ps:scale worker=1` and a new container will be
started by running `docker run bin/run-worker.sh` (the actual `docker run` commands are a bit more
complex, but this is the basic idea). If you use an `ENTRYPOINT` in your `Dockerfile`, the lines
in your `Procfile` will be passed as arguments to the `ENTRYPOINT` script instead of being executed.
