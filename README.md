This is a fork of the real project are [HERE](https://github.com/gmag11/MetaTrader5-Docker-Image) all thanks are on this developer, i only recrate for work with MetaTrader4, the creator are [gmag11](https://github.com/gmag11)

# MetaTrader4 Docker Image

This project provides a Docker image for running MetaTrader4 with remote access via VNC, based on the [KasmVNC](https://github.com/kasmtech/KasmVNC) project and [KasmVNC Base Image from LinuxServer](https://github.com/linuxserver/docker-baseimage-kasmvnc).

## Features

- Run MetaTrader4 in an isolated environment.
- Remote access to MetaTrader4 interface via an integrated VNC client accessible through a web browser.
- Built on the reliable and secure [KasmVNC](https://github.com/kasmtech/KasmVNC) project.
- RPyC server for remote access to Python MetaTrader Library from Windows or Linux using https://github.com/lucas-campagna/mt5linux

![MetaTrader5 running inside container and controlled through web browser](https://imgur.com/v6Hm9pa.png)

---

**NOTICE:**
Due to some compatibility issued, version 2 has switched its base from Alpine to Debian Linux. This and adding Python environment makes that container size is considerably bigger from about 600 MB to 4 GB.

If you just need to run Metatrader for running your MQL5 programs without any Python programming I recommend to go on using version 1.0. MetaTrader program is updated independently from image so you will always have latest MT4 version.

---

## Requirements

- Docker installed on your machine.
- Only intelx86/amd64 host is supported

## Usage from repository

1. Clone this repository:

```bash
git clone https://github.com/DavideSantos/MetaTrader4-Docker-Image
cd MetaTrader4-Docker-Image
```

2. Build the Docker image:

```bash
docker build -t mt4 .
```

3. Run the Docker image:

```bash
docker run -d -p 4001:3000 -p 9001:8001 -v config_1:/config mt4
```

Now you can access MetaTrader5 via a web browser at localhost:4001.

On first run it may take a few minutes to get everything installed and running. Normally it takes less than 5 minutes. You don't need to do anything. All installation process is automatic and you should end up with MetaTrader5 running in your web session.

## Usage with docker compose with image form Docker Registry (preferred way)

1. Create a folder in a path where you have permission. For instance in your home.

```bash
mkdir MT4
cd MT4
```

2. Create `docker-compose.yaml` file.

```bash
nano docker-compose.yaml
```

Use this content filling user and password with your own data.

```yaml
services:
  mt4_1:
    container_name: mt4_1
    image: mt4
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - ./config_1:/config
    ports:
      - 4001:3000
      - 9001:8001
    env_file:
      - .env
    deploy:
      resources:
        limits:
          cpus: "6.0"
          memory: 16G
        reservations:
          cpus: "0.25"
          memory: 512M
    restart: unless-stopped
    networks:
      - portainer-nginx-proxy-manager_default #change this to your network
    logging:
      options:
        max-size: "10m"
        max-file: "3"
```

1. Start the container or a single service

```bash
docker compose up -d
or
docker compose up -d mt4_1
```

In some systems `docker compose` command does not exists. Try to use `docker-compose up -d` instead.

4. Connect to web interface
   Start your browser pointing http://<your ip address>:4001

On first run it may take a few minutes to get everything installed and running. Normally it takes less than 5 minutes. You don't need to do anything. All installation process is automatic and you should end up with MetaTrader5 running in your web session.

## Where to place MQ5 and EX5 files

In the case you want to run your own MQL5 bots inside the container you can find MQL5 folder structure in

```
config/.wine/drive_c/Program Files/MetaTrader 4/MQL5
```

All files that you place there can be accessed from your MetaTrader container without the need to restart anything.

You can access MetaEditor program clicking in `IDE` button in MetaTrader4 interface.

**Notice**: If you will run MQL5 only bots (without Python) you can run perfectly with gmag11/metatrader5_vnc:1.0 image as pointed before. Remember that **image version is not stuck to a specific MetaTrader 5 version**.

**Metatrader will always be updated automatically to latest version as it does when it is nativelly installed in Windows.**

## Python programming

You need to install [mt5linux library](https://github.com/lucas-campagna/mt5linux) in your Python host. It may be in any OS, not only Linux.

This is a simple snippet to run your Python script fron any host

```python
from mt5linux import MetaTrader5
mt5 = MetaTrader5(host='host running docker container',port=8001)
mt5.initialize()
print(mt5.version())
```

Output should be something like this:

```
(mt5linux) linux:~/$ python3
Python 3.10.13 (main, Dec 26 2023, 20:21:41) [GCC 13.2.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> from mt5linux import MetaTrader5
>>> mt5 = MetaTrader5(host='192.168.1.10',port=8001)
>>> mt5.initialize()
True
>>> print(mt5.version())
(500, 4120, '22 Dec 2023')
>>>
```

## Configuration

The port configuration can be adjusted as per the instructions in the KasmVNC repository. Any additional configuration or environment variables needed to customize MetaTrader5 and KasmVNC running settings should be described here.

## Contributions

Feel free to contribute to this project. All contributions are welcome. Open an issue or create a pull request.

## License

This project is licensed under the terms of the [MIT license](https://opensource.org/license/mit/).

The [**KasmVNC**](https://github.com/kasmtech/KasmVNC) project is licensed under the [GNU General Public License v2.0 (GPLv2)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html). You can check the license details of KasmVNC [here](https://github.com/kasmtech/KasmVNC/blob/master/LICENSE.TXT).

[**KasmVNC Base Image from LinuxServer**](https://github.com/linuxserver/docker-baseimage-kasmvnc) is licensed unther the GNU General Public License v3.0 (GPLv3). License is available [here](https://github.com/linuxserver/docker-baseimage-kasmvnc/blob/master/LICENSE)

Please ensure to comply with the terms and conditions of the licenses while using or modifying this project.

# Acknowledgments

Acknowledgments to the [KasmVNC](https://github.com/kasmtech/KasmVNC) project, [KasmVNC Base Image from LinuxServer](https://github.com/linuxserver/docker-baseimage-kasmvnc/tree/master), [mt5linux library](https://github.com/lucas-campagna/mt5linux) and any other project or individual that contributed to the realization of this project.
