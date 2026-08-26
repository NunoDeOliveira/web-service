# Host as admin station. IP: 10.0.0.50

## 1. Asignar la IP de Admin al bridge Management

```bash
sudo ip addr add 10.0.0.50/29 dev virbr50
```

Comprueba:

```bash
ip -br addr show virbr50
```

Debe aparecer:

```text
virbr50   UP   10.0.0.50/29
```

Esto convierte el host en el equipo **Admin `10.0.0.50`** dentro de Management.

---

## 2. Añadir las redes que están detrás de FW2

### DMZ

```bash
sudo ip route add 10.0.0.32/28 via 10.0.0.49 dev virbr50
```

Significa:

> Para llegar a la DMZ, usa FW2 Management (`10.0.0.49`) como gateway.

### Internal

```bash
sudo ip route add 10.0.0.0/27 via 10.0.0.49 dev virbr50
```

Significa:

> Para llegar a Internal, usa también FW2.

El portátil queda así:

```text
Admin PC 10.0.0.50
        |
   Management
        |
   FW2 10.0.0.49
      /       \
    DMZ      Internal
```

---

## 3. Comprobar las rutas del portátil

```bash
ip route
```

Debería aparecer:

```text
10.0.0.48/29 dev virbr50
10.0.0.32/28 via 10.0.0.49 dev virbr50
10.0.0.0/27 via 10.0.0.49 dev virbr50
```

El `default` normal **no cambia**.

---

## 4. Probar Management → FW2

```bash
ping -c 3 10.0.0.49
```

Debe funcionar porque FW2 está directamente conectado a Management.

---

## 5. Probar Management → DMZ

FW1:

```bash
ping -c 3 10.0.0.33
```

Web Server:

```bash
ping -c 3 10.0.0.34
```

---

## 6. Probar SSH administrativo hacia FW1

```bash
ssh root@10.0.0.33
```

El camino será:

```text
10.0.0.50
   ↓
FW2 Management .49
   ↓
FW2 DMZ .46
   ↓
FW1 DMZ .33
```

**Este es el SSH que se quiere conservar cuando se active nftables.**

Después FW1 podrá tener:

```nft
ip saddr 10.0.0.50 tcp dport 22 accept
```

y se bloquea SSH desde External.

---

## 7. Importante: ahora es temporal

Estos cambios:

```bash
ip addr add ...
ip route add ...
```

desaparecen al reiniciar sesión.


### Fuentes

* **LPIC-2 — Topic 205, Networking Configuration:** direcciones, gateways y rutas estáticas.
* **LPIC-2 — Objective 212.3, Secure Shell:** administración remota mediante SSH.
