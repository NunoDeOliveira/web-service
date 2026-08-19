## Configure SSH account for admin

SSH provides encrypted remote administration. In this topology, the Admin machine (`10.0.0.50`) accesses the web server (`10.0.0.34`) through FW2.

### 1. Check SSH service

LPIC-1 explains the use of the ssh.socket systemd unit for SSH and shows that port TCP 22 is used for incoming SSH connections. So, now check if SSH socket activation is active and check if the service also is active:

```bash
systemctl status ssh.socket
```

```bash
systemctl status ssh.service
```

Check which process is listening on port 22:

```bash
sudo lsof -i :22 -P
```

### 2. Activate SSH service.

I the sockets are not working active, start daemon and enable socket

```bash
sudo systemctl start ssh.socket
sudo systemctl enable ssh.socket
```
After starting and enable sockets, restart the ssh service

```bash
sudo systemctl restart ssh.service
```
and check the state of socket and service

![check-status-socket-ok.png](/check-status-socket-ok.png)

![check-service-ssh-is-working.png](/check-service-ssh-is-working.png)


### 3. Generete ssh keys using elliptic curve algorithm.

```bash
ssh-keygen -t ed25519 -f ~/.ssh/webserver_admin
```

This step creates private key

```bash
~/.ssh/webserver_admin
```
and the public key 

```bash
~/.ssh/webserver_admin.pub
```

### 4. Copy the Admin public key

From the admin amchine copy the public key

```bash
ssh-copy-id -i ~/.ssh/webserver_admin.pub nuno@192.168.122.236
```
into Web Server on directory `/home/nuno/.ssh/authorized_keys`

![cheking-pub-key-copied-in-web-server.png](/cheking-pub-key-copied-in-web-server.png)

### 5. For testing ssh connection

```bash
ssh -i ~/.ssh/webserver_admin nuno@10.0.0.34
```

### 6. Create a secure sever rules

After key authentication, a file configuration is created for 

```bash
sudo nano /etc/ssh/sshd_config.d/10-web-server-security.conf
```

and add:

`PermitRootLogin no`
`PubkeyAuthentication yes`
`PasswordAuthentication no`
`AllowUsers nuno dev`

this gives root conection denied, will allowed to connection for admin group and will deny other users.



## Configure SSH for deployment

### 1. Generate the developer key

From developer machine

```bash
ssh-keygen -t ed25519 -f ~/.ssh/webserver_developer
```

Copy its public key to the existing dev account:

```bash
ssh-copy-id -i ~/.ssh/webserver_developer.pub dev@10.0.0.34
```

this key will be saved into `/home/dev/.ssh/authorized_keys`

### 2. 



References:
- LPI Learning Material LPIC-1 — Topic 102.6, Secure access to cloud guests: ssh-keygen, ssh-copy-id, private/public keys and authorized_keys.
- LPI Learning Material LPIC-1 — Topic 110.3, Protecting data with encryption: key-based SSH login and authorized_keys.
- LPIC-2 — Objective 204.4 Advanced Secure Shell:


