
When you installed Jenkins, it didn't become a program you open and close. It became a **service**: a program that Linux starts for you, keeps running without a terminal, and can restart if it crashes. On Debian, the thing that manages services is called **systemd**, and its control tool is `systemctl`. Postgres, Nginx, Tomcat and Jenkins all work this way.

The good news is that you only need to learn two separate ideas, and everything else follows from them. The first is _is it running right now?_ The second is _will it start by itself at boot?_ They are independent switches, and most confusion comes from mixing them up.

## The two switches

|Command|Running now?|Starts at boot?|
|---|---|---|
|`systemctl start jenkins`|yes|unchanged|
|`systemctl stop jenkins`|no|unchanged|
|`systemctl enable jenkins`|unchanged|yes|
|`systemctl disable jenkins`|unchanged|no|
|`systemctl enable --now jenkins`|yes|yes|
|`systemctl disable --now jenkins`|no|no|

`--now` just means "do the start or stop as well". So `start`/`stop` change the present, and `enable`/`disable` change the future.

Here is how that looks as states:

|State|Meaning|
|---|---|
|enabled + active|Running, and comes back after reboot|
|disabled + active|Running now, gone after reboot|
|enabled + inactive|Not running now, but will start at next boot|
|disabled + inactive|Fully off|

You can read both switches with:

```bash
systemctl is-enabled jenkins
systemctl is-active jenkins
```

## What "enable" actually does

Remember this line from your install output?

```
Created symlink '/etc/systemd/system/multi-user.target.wants/jenkins.service'
→ '/usr/lib/systemd/system/jenkins.service'
```

Read it as: "put a shortcut in the folder of things to start at boot." Two paths are involved:

- `/usr/lib/systemd/system/jenkins.service` is the real **unit file**, installed by the package. It describes how to run Jenkins.
- `/etc/systemd/system/multi-user.target.wants/` is a folder of shortcuts. `multi-user.target` is the normal "system is fully booted, no desktop needed" stage, and everything linked in its `wants` folder is started at that stage.

So `enable` just creates that symlink, and `disable` deletes it. Nothing magic happens.

## The unit file, line by line

You can see the real one with:

```bash
systemctl cat jenkins
```

The real file is longer, but a simplified version looks like this:

```ini
[Unit]
Description=Jenkins Continuous Integration Server
After=network.target

[Service]
User=jenkins
ExecStart=/usr/bin/jenkins
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

- `Description=` is the label you see in `systemctl status`.
- `After=network.target` means "start me after networking is up". It controls the order, so Jenkins doesn't launch before the network exists.
- `User=jenkins` runs it as the `jenkins` user that the package created, not as root and not as you. If Jenkins is ever compromised, it can only touch what that user can touch.
- `ExecStart=` is the actual command that launches the program.
- `Restart=on-failure` means systemd relaunches it if it crashes. This is what "keeps running in the background" really means.
- `WantedBy=multi-user.target` is the line that `enable` reads. It says which stage should pull this service in, and it is the reason the symlink above lands in `multi-user.target.wants`.

The `[Install]` section is only used by `enable` and `disable`. The other two sections are used whenever the service runs.

## Reading what happened

When something misbehaves, you have two tools:

```bash
systemctl status jenkins              # state, process ID, and the last few log lines
journalctl -u jenkins -n 50 --no-pager   # the last 50 log lines
journalctl -u jenkins -f              # follow the log live (Ctrl+C to stop)
```

`journalctl` is the central log reader for systemd. The `-u` flag filters by unit, so you only see Jenkins lines. Services have no terminal, so their output goes to the journal instead of your screen. That's why you read it with `journalctl`.

The status word tells you the story quickly:

|Status|What it means|
|---|---|
|`active (running)`|Healthy|
|`inactive (dead)`|Stopped cleanly, nothing wrong|
|`failed`|It crashed or couldn't start, so read the journal|
|`activating`|Still starting, and Jenkins takes about a minute|

## Changing a service without breaking the package

If you edit `/usr/lib/systemd/system/jenkins.service` directly, a package update can overwrite your change. Instead, use an **override**:

```bash
sudo systemctl edit jenkins
```

This creates a small file in `/etc/systemd/system/jenkins.service.d/` that is layered on top of the original. That's what we did earlier to change the port with `Environment="JENKINS_PORT=8081"`. After any change to unit files, apply it with:

```bash
sudo systemctl daemon-reload   # re-read unit files
sudo systemctl restart jenkins
```

`daemon-reload` doesn't touch your services. It only tells systemd to re-read the files, and it's needed whenever a unit file changed.

## Why it costs memory

Because the service is a Java app, it keeps a JVM alive the whole time, and you can see that with `systemctl status jenkins` (look at the `Memory:` line). This connects to your JVM memory lesson: the heap Jenkins reserves stays allocated while it runs, even when no one is using it. Stopping the service frees all of it, and your jobs and settings stay safe in `/var/lib/jenkins`.

## Related: how this compares to other ways of running things in the background

- **Docker** does the same job with a different tool. Instead of `enable`, you give a container `--restart unless-stopped`, and the Docker daemon (itself a systemd service) brings the container back after reboot.
- **systemd timers** are the modern replacement for cron. A timer unit runs a service on a schedule, instead of keeping it alive all the time.
- **Running in a terminal** (`java -jar app.jar`) ties the program to that terminal, so closing it kills the app. A service doesn't have that limit, which is why you deploy your Spring Boot apps this way on a server, the same idea as in your Tomcat and Nginx lesson.

## Quick practice

Try these in order and watch the output each time:

```bash
systemctl is-enabled jenkins
systemctl is-active jenkins
sudo systemctl stop jenkins
systemctl is-active jenkins      # inactive
systemctl is-enabled jenkins     # still enabled
sudo systemctl disable jenkins
systemctl is-enabled jenkins     # disabled
sudo systemctl enable --now jenkins
```




[[CICD]]