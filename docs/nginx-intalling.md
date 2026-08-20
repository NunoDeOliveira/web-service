## Installing NGINX

**1. NGINX intalation:**
 
For systems baseded in Debian or Ubuntu, the instalation of NINX is carried out using the following command:

```bash
sudo apt update && sudo apt upgrade
```

```bash
sudo apt-get install nginx
```

This command download, install and initialize automaticly the Nginx service. After installing, put enable nginx daemon, and check the state using this command:

```bash
sudo systemctl enable --now nginx
```

```bash
sudo systemctl status nginx
```

The result:

![Nginx running](screenshots/nginx-status-enable.png)


**2. Port used by NGINX:**

The default way, Nginx starts up listening on TCP port 80, which is the stándar Network port for HTTP traffic.
However, will be necessary configurate the 443 port for TLS protocol for HTTPS traffic. For checking if the nginx is listening in default port:

```bash
ss -lntp | grep ':80'
```

and try a HTTP request:

```bash
curl -I http://localhost
```

![Nginx working](screenshots/nginx-check-port-and-http-request.png)


**3. Location in Ubuntu server for Nginx configuration:**

Alll the files od Nginx are stored in the /etc/nginx directory. The global configuration file of Nginx is:

```bash
/etc/nginx/nginx.conf
```

For Debian and Ubuntu, the directives and settings for the web site, by default is defined in the file:

```bash
/etc/nginx/sites-enable/default
```
This the configuration of site
 
**4. Content web**

Here is the content that Nginx publishes

```bash
/var/www/html/index.nginx-debian.html
```

**5. How the parametes of Nginx is configured?**

The Nginx parameters of configuration is defined by structured blocks into configuration files. 

- Block `server {...}` 
- Block `location {...}`

---

**Note:** is important carry out the TCP Wrappers checking because a network servive must have explicity support for TCP Wrappers, for in order to benefit from the access control and restriction lists that this technology provides.
To check whether your installed Nginx binary is compatible with this library, run the following command:

```bash
ldd /usr/sbin/sbin/nginx | grep "libwrap"
```

If Nginx supports TCP Wrappers, the command output will display the link path to the libwrap.so library on the system 
















