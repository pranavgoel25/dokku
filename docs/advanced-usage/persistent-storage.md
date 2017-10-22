# Persistent Storage

> New as of 0.5.0

The preferred method to mount external containers to a Dokku managed container, is to use the Dokku storage plugin.


```
storage:list <app>                             # List bind mounts for app's container(s) (host:container)
storage:mount <app> <host-dir:container-dir>   # Create a new bind mount
storage:unmount <app> <host-dir:container-dir> # Remove an existing bind mount
```

## Ideology and Background

The storage plugin requires explicit paths on the host side. This is intentional to ensure that new users avoid running into unexpected results with implicit paths that may not exist (a feature deprecate in [Docker 1.9.0](https://github.com/docker/docker/releases/tag/v1.9.0])). The container directory is created for the mount point in the container. Any existing directory contents are not accessible after a mount is added to the container. Dokku creates a new directory `/var/lib/dokku/data/storage` during installation, it's the general consensus that new users should use this directory. Mounts are only available at run and deploy times, you must redeploy (restart) an app to mount or unmount to an existing app's container.

## Usage

This example demonstrates how to mount the recommended directory to `/storage` inside the container:

```shell
dokku storage:mount app-name /var/lib/dokku/data/storage:/storage
```

Dokku will then mount the shared contents of `/var/lib/dokku/data/storage` to `/storage` inside the container.

A more complete workflow may require making a custom directory for your application and mounting it within your `/app/storage` directory instead. The mount point is *not* relative to your application's working directory, and is instead relative to the root of the container.

```shell
# creating storage for the app 'ruby-rails-sample'
mkdir -p  /var/lib/dokku/data/storage/ruby-rails-sample

# ensure the proper user has access to this directory
chown -R dokku:dokku /var/lib/dokku/data/storage/ruby-rails-sample

# as of 0.7.x, you should chown using the `32767` user and group id
chown -R 32767:32767 /var/lib/dokku/data/storage/ruby-rails-sample

# mount the directory into your container's /app/storage directory, relative to root
dokku storage:mount app-name /var/lib/dokku/data/storage/app-name:/app/storage
```

You can mount one or more directories as desired by following the above pattern.

## Use Cases

### Persistent storage

Dokku is powered by Docker containers, which recommends in their [best practices](https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#containers-should-be-ephemeral) that containers be treated as ephemeral. In order to manage persistent storage for web applications, like user uploads or large binary assets like images, a directory outside the container should be mounted.

### Shared storage between containers

When scaling your app, you may require a common location to access shared assets between containers, a storage mount can be used in this situation.

### Shared storage across environments

Your app may be used in a cluster that requires containers or resources not running on the same host access your data. Mounting a shared file service (like S3FS or EFS) inside your container will give you great flexibility.

### Backing up

Your app may have services that are running in memory and need to be backed up locally (like a key store). Mount a non ephemeral storage mount will allow backups that are not lost when the app is shut down.

### Build phase

By default, Dokku will only bind storage mounts during the deploy and run phases. Under certain conditions, one might want to bind a storage mount during the build phase. This can be accomplished by using the `docker-options` plugin directly.

```shell
dokku docker-options:add <app> build "-v /tmp/python-test:/opt/test"
```

You cannot use mounted volumes during the build phase of a Dockerfile deploy. This is because Docker does not support volumes when executing `docker build`.

> Note: **This can cause data loss** if you bind a mount under `/app` in buildpack apps as herokuish will attempt to remove the original app path during the build phase.

## Docker-Options Note

The storage plugin is compatible with storage mounts created with the docker-options. The storage plugin will only list mounts from the deploy phase.


> New as of 0.7.1

## Application User and Persistent Storage file ownership (buildpack apps only)

By default, Dokku will execute your buildpack application processes as the `herokuishuser` user. You may override this by setting the `DOKKU_APP_USER` config variable.

> NOTE: this user must exist in your herokuish image.

Additionally, Dokku will ensure your storage mounts are owned by either `herokuishuser` or the overridden value you have set in `DOKKU_APP_USER`.
