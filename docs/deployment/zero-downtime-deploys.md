# Zero Downtime Deploys

> New as of 0.5.0

```
checks <app>                             Show zero-downtime status
checks:disable <app> [process-type(s)]   Disable zero-downtime deployment for all processes (or comma-separated process-type list) ***WARNING: this will cause downtime during deployments***
checks:enable <app> [process-type(s)]    Enable zero-downtime deployment for all processes (or comma-separated process-type list)
checks:run <app> [process-type(s)]       Runs zero-downtime checks for all processes (or comma-separated process-type list)
checks:skip <app> [process-type(s)]      Skip zero-downtime checks for all processes (or comma-separated process-type list)
```

Following a deploy, Dokku will wait `10` seconds before routing traffic to the new container to give your application time to boot up. If the application is not running after this time, then the deploy is failed and your old container will continue serving traffic. You can modify this value globally or on a per-application basis:

```shell
dokku config:set --global DOKKU_DEFAULT_CHECKS_WAIT=30
dokku config:set node-js-app DOKKU_DEFAULT_CHECKS_WAIT=30
```

You can also choose to skip checks or disable zero-downtime completely on a per-application/per-process basis

> Note that `checks:disable` will now (as of 0.6.0) cause downtime for that process-type during deployments.

```shell
dokku checks:skip node-js-app worker,web
```

```
-----> Skipping zero downtime for app's (node-js-app) proctypes (worker,web)
-----> Unsetting node-js-app
-----> Unsetting DOKKU_CHECKS_DISABLED
-----> Setting config vars
       DOKKU_CHECKS_SKIPPED: worker,web
```

Additionally, any given process can only be configured to disable zero-downtime. example:


```shell
dokku checks:disable node-js-app worker
```

```
-----> Disabling zero downtime for app's (node-js-app) proctypes (worker)
-----> Setting config vars
       DOKKU_CHECKS_DISABLED: worker
-----> Setting config vars
       DOKKU_CHECKS_SKIPPED: web
```

Dokku will wait `60` seconds before stopping the old container so that existing connections are given a chance to complete. You can modify this value globally or on a per-application basis:

```shell
dokku config:set --global DOKKU_WAIT_TO_RETIRE=120
dokku config:set <app> DOKKU_WAIT_TO_RETIRE=120
```

> Note that during this time, multiple containers may be running on your server, which can be an issue for memory-hungry applications on memory-constrained servers.

## Manually Invoking Checks

Checks can also be manually invoked via the `checks:run` command. This can be used to check the status of an application via cron to provide integration with external healthchecking software.

Checks are run against a specific application:

```shell
dokku checks:run APP
```

```
-----> Running pre-flight checks
-----> Running checks for app (APP.web.1)
       For more efficient zero downtime deployments, create a file CHECKS.
       See http://dokku.viewdocs.io/dokku/checks-examples.md for examples
       CHECKS file not found in container: Running simple container check...
-----> Waiting for 10 seconds ...
-----> Default container check successful!
-----> Running checks for app (APP.web.2)
       For more efficient zero downtime deployments, create a file CHECKS.
       See http://dokku.viewdocs.io/dokku/checks-examples.md for examples
       CHECKS file not found in container: Running simple container check...
-----> Waiting for 10 seconds ...
-----> Default container check successful!
-----> Running checks for app (APP.worker.1)
       For more efficient zero downtime deployments, create a file CHECKS.
       See http://dokku.viewdocs.io/dokku/checks-examples.md for examples
       CHECKS file not found in container: Running simple container check...
-----> Waiting for 10 seconds ...
-----> Default container check successful!
```

Checks can be scoped to a particular process type:

```shell
dokku checks:run APP worker
```

```
-----> Running pre-flight checks
-----> Running checks for app (APP.worker.1)
       For more efficient zero downtime deployments, create a file CHECKS.
       See http://dokku.viewdocs.io/dokku/checks-examples.md for examples
       CHECKS file not found in container: Running simple container check...
-----> Waiting for 10 seconds ...
-----> Default container check successful!
```

An app process id may also be specified:

```shell
dokku checks:run APP web.2
```

```
-----> Running pre-flight checks
-----> Running checks for app (APP.web.2)
       For more efficient zero downtime deployments, create a file CHECKS.
       See http://dokku.viewdocs.io/dokku/checks-examples.md for examples
       CHECKS file not found in container: Running simple container check...
-----> Waiting for 10 seconds ...
-----> Default container check successful!
```

Non-existent process types will result in an error:

```shell
dokku checks:run APP non-existent
```

```
-----> Running pre-flight checks
Invalid process type specified (APP.non-existent)
```

Non-existent process ids will *also* result in an error

```shell
dokku checks:run APP web.3
```

```
-----> Running pre-flight checks
Invalid container id specified (APP.web.3)
```

## Customizing Checks

If your application needs a longer period to boot up - perhaps to load data into memory, or because of slow boot time - you may also use dokku's `checks` functionality to more precisely check whether an application can serve traffic or not.

Checks are run against the detected `web` process from your application's `Procfile`. For non-web processes, Dokku will fallback to the aforementioned process uptime check.

To specify checks, add a `CHECKS` file to the root of your project directory. The `CHECKS` file should be plain text and may contain:

* Check instructions
* Settings (NAME=VALUE)
* Comments (lines starting with #)
* Empty lines

> For dockerfile-based deploys, the file *must* be in `/app/CHECKS` within the container. `/app` is used by default as the root container directory for buildpack-based deploys.

### Check Instructions

The format of a check instruction is a path or relative URL, optionally followed by the expected content:

```
/about  Our Amazing Team
```

The `CHECKS` file can contain multiple checks:

```
/                       My Amazing App
/stylesheets/index.css  .body
/scripts/index.js       $(function()
/images/logo.png
```

To check an application that supports multiple hostnames, use relative URLs that include the hostname:

```
//admin.example.com  Admin Dashboard
//static.example.com/logo.png
```

You can also specify the protocol to explicitly check HTTPS requests:

```
https://admin.example.com  Admin Dashboard
https://static.example.com/logo.png
```

### Check Settings

The default behavior is to wait for `5` seconds before running the checks, to timeout the checks after `30` seconds, and to attempt the checks `5` times. If the checks fail `5` times, the deployment is considered failed and the old container will continue serving traffic.

You can change the default behavior by setting `WAIT`, `TIMEOUT`, and `ATTEMPTS` to different values in the `CHECKS` file:

```
WAIT=30     # Wait 1/2 minute
TIMEOUT=60  # Timeout after a minute
ATTEMPTS=10 # Attempt checks 10 times

/  My Amazing App
```

You can also override the default `WAIT`, `TIMEOUT`, and `ATTEMPTS` variables for the global Dokku installation:

```shell
dokku config:set --global DOKKU_CHECKS_WAIT=30
dokku config:set --global DOKKU_CHECKS_TIMEOUT=60
dokku config:set --global DOKKU_CHECKS_ATTEMPTS=10
```

If your application runs multiple processes (a background worker configured in your `Procfile`, for example) and you have checks to ensure that your web application has booted up, you may want to disable the default check wait time for that application to avoid the `10` second wait per non-web process:

```shell
dokku config:set <app> DOKKU_DEFAULT_CHECKS_WAIT=0
```

### Configuring docker stop timeout

[By default](https://docs.docker.com/engine/reference/commandline/stop/), docker will wait 10 seconds from the time the `stop` command is passed to a container before it attempts to kill said container. This timeout can be configured on a per-app basis in Dokku by setting the `DOKKU_DOCKER_STOP_TIMEOUT` configuration variable. This timeout applies to normal zero-downtime deployments as well as the `ps:stop` and `apps:destroy` commands.

```shell
dokku config:set $APP DOKKU_DOCKER_STOP_TIMEOUT=20
```

## Example: Successful Rails Deployment

In this example, a Rails application is successfully deployed to dokku. The initial round of checks fails while the server is starting, but once it starts they succeed and the deployment is successful. `WAIT` is set to `10` because our application takes a while to boot up. `ATTEMPTS` is set to `6`, but the third attempt succeeds.

### CHECKS file

```
WAIT=10
ATTEMPTS=6
/check.txt  simple_check
```

For this check to work, we've added a line to `config/routes.rb` that simply returns a string:

```
get '/check.txt', to: proc {[200, {}, ['simple_check']]}
```

### Deploy Output

> Note: The output has been trimmed for brevity

```shell
git push dokku master
```

```
-----> Cleaning up...
-----> Building myapp from herokuish...
-----> Adding BUILD_ENV to build environment...
-----> Ruby app detected
-----> Compiling Ruby/Rails
-----> Using Ruby version: ruby-2.0.0

.....

-----> Discovering process types
       Procfile declares types -> web
-----> Releasing myapp...
-----> Deploying myapp...
-----> Running pre-flight checks
-----> Attempt 1/6 Waiting for 10 seconds ...
       CHECKS expected result:
       http://localhost/check.txt => "simple_check"
 !
curl: (7) Failed to connect to 172.17.0.155 port 5000: Connection refused
 !    Check attempt 1/6 failed.
-----> Attempt 2/6 Waiting for 10 seconds ...
       CHECKS expected result:
       http://localhost/check.txt => "simple_check"
 !
curl: (7) Failed to connect to 172.17.0.155 port 5000: Connection refused
 !    Check attempt 2/6 failed.
-----> Attempt 3/6 Waiting for 10 seconds ...
       CHECKS expected result:
       http://localhost/check.txt => "simple_check"
-----> All checks successful!
=====> myapp container output:
       => Booting Thin
       => Rails 4.2.0 application starting in production on http://0.0.0.0:5000
       => Run `rails server -h` for more startup options
       => Ctrl-C to shutdown server
       Thin web server (v1.6.3 codename Protein Powder)
       Maximum connections set to 1024
       Listening on 0.0.0.0:5000, CTRL+C to stop
=====> end myapp container output
-----> Running post-deploy
-----> Configuring myapp.dokku.example.com...
-----> Creating http nginx.conf
-----> Running nginx-pre-reload
       Reloading nginx
-----> Shutting down old container in 60 seconds
=====> Application deployed:
       http://myapp.dokku.example.com
```

## Example: Failing Rails Deployment

In this example, a Rails application fails to deploy. The reason for the failure is that the postgres database connection fails. The initial checks will fail while we wait for the server to start up, just like in the above example. However, once the server does start accepting connections, we will see an error 500 due to the postgres database connection failure.

Once the attempts have been exceeded, the deployment fails and we see the container output, which shows the Postgres connection errors.

### CHECKS file

```
WAIT=10
ATTEMPTS=6
/
```

> The check to the root url '/' would normally access the database.

### Deploy Output

> Note: The output has been trimmed for brevity

```shell
git push dokku master
```

```
-----> Cleaning up...
-----> Building myapp from herokuish...
-----> Adding BUILD_ENV to build environment...
-----> Ruby app detected
-----> Compiling Ruby/Rails
-----> Using Ruby version: ruby-2.0.0

.....

Discovering process types
Procfile declares types -> web
Releasing myapp...
Deploying myapp...
Running pre-flight checks
-----> Attempt 1/6 Waiting for 10 seconds ...
       CHECKS expected result:
       http://localhost/ => ""
 !
curl: (7) Failed to connect to 172.17.0.188 port 5000: Connection refused
 !    Check attempt 1/6 failed.
-----> Attempt 2/6 Waiting for 10 seconds ...
       CHECKS expected result:
       http://localhost/ => ""
 !
curl: (7) Failed to connect to 172.17.0.188 port 5000: Connection refused
 !    Check attempt 2/6 failed.
-----> Attempt 3/6 Waiting for 10 seconds ...
       CHECKS expected result:
       http://localhost/ => ""
 !
curl: (22) The requested URL returned error: 500 Internal Server Error
 !    Check attempt 3/6 failed.
-----> Attempt 4/6 Waiting for 10 seconds ...
       CHECKS expected result:
       http://localhost/ => ""
 !
curl: (22) The requested URL returned error: 500 Internal Server Error
 !    Check attempt 4/6 failed.
-----> Attempt 5/6 Waiting for 10 seconds ...
       CHECKS expected result:
       http://localhost/ => ""
 !
curl: (22) The requested URL returned error: 500 Internal Server Error
 !    Check attempt 5/6 failed.
-----> Attempt 6/6 Waiting for 10 seconds ...
       CHECKS expected result:
       http://localhost/ => ""
 !
curl: (22) The requested URL returned error: 500 Internal Server Error
Could not start due to 1 failed checks.
 !    Check attempt 6/6 failed.
=====> myapp container output:
       => Booting Thin
       => Rails 4.2.0 application starting in production on http://0.0.0.0:5000
       => Run `rails server -h` for more startup options
       => Ctrl-C to shutdown server
       Thin web server (v1.6.3 codename Protein Powder)
       Maximum connections set to 1024
       Listening on 0.0.0.0:5000, CTRL+C to stop
       Started GET "/" for 172.17.42.1 at 2015-03-26 21:36:47 +0000
         Is the server running on host "172.17.42.1" and accepting
         TCP/IP connections on port 5431?
       PG::ConnectionBad (could not connect to server: Connection refused
         Is the server running on host "172.17.42.1" and accepting
         TCP/IP connections on port 5431?
       ):
         vendor/bundle/ruby/2.0.0/gems/activerecord-4.2.0/lib/active_record/connection_adapters/postgresql_adapter.rb:651:in `initialize'
         vendor/bundle/ruby/2.0.0/gems/activerecord-4.2.0/lib/active_record/connection_adapters/postgresql_adapter.rb:651:in `new'
         vendor/bundle/ruby/2.0.0/gems/activerecord-4.2.0/lib/active_record/connection_adapters/postgresql_adapter.rb:651:in `connect'
         vendor/bundle/ruby/2.0.0/gems/activerecord-4.2.0/lib/active_record/connection_adapters/postgresql_adapter.rb:242:in `initialize'
         vendor/bundle/ruby/2.0.0/gems/activerecord-4.2.0/lib/active_record/connection_adapters/postgresql_adapter.rb:44:in `new'
         vendor/bundle/ruby/2.0.0/gems/activerecord-4.2.0/lib/active_record/connection_adapters/postgresql_adapter.rb:44:in `postgresql_connection
=====> end myapp container output
/usr/bin/dokku: line 49: 23409 Killed                  dokku deploy "$APP"
To dokku@dokku.example.com:myapp
 ! [remote rejected] dokku -> master (pre-receive hook declined)
error: failed to push some refs to 'dokku@dokku.example.com:myapp'
```
