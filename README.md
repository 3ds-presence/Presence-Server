# Presence-3DS Server
This project is part of the [Presence-3DS](https://github.com/3ds-presence/) project.

This repo contains all the parts of the Presence-3DS project as submodules, including the backend API (backend and activity generator) and the frontend

Use docker to orchestrate and compile and start the different parts of the project.

Also setup a reverse proxy to link the frontend and the backend API to a domain name.

## Usage
Edit the `.env` file to set your own configuration, then run the following command to start the project:
```bash
docker compose up -d
```

## Warning
You must use another reverse proxy (like Nginx Proxy Manager) to expose this nginx instance to the internet. This nginx instance is only used to link the frontend and the backend API together, and should not be exposed directly to the internet.
Otherwise, the IP address of the client can be spoofed, and the backend API will not be able to get the real IP address of the client.