Description of problem:


Output of the following commands

- `uname -a`:
- `free -m`:
- `docker version`:
- `docker -D info`:
- `sigil -v`:
- `docker run -ti gliderlabs/herokuish:latest herokuish version`:
- `dokku version`:
- `dokku plugin`:
- `docker inspect CONTAINER_ID` (if applicable):
  (BEWARE: `docker inspect` will print environment variables for some commands, be sure you're not exposing any sensitive information when posting issues. You may replace these values with XXXXXXX):
- `cat /home/dokku/<app>/nginx.conf` (if applicable):
- Link to the exact repository being deployed (if possible/applicable):
- If a deploy is failing or behaving unexpectedly:
  - Application name
  - The type of application being deployed (node, php, python, ruby, etc.)
  - If using buildpacks, which custom buildpacks are in use
  - If using a `Dockerfile`, the contents of that file
  - If it exists, the contents of your `Procfile`.
- Output of failing Dokku commands after running `dokku trace on`
  (BEWARE: `trace on` will print environment variables for some commands, be sure you're not exposing any sensitive information when posting issues. You may replace these values with XXXXXXX):

Environment details (AWS, VirtualBox, physical, etc.):

How was Dokku installed?:

How reproducible:


Steps to Reproduce:
1.
2.
3.

Actual Results:


Expected Results:


Additional info:
