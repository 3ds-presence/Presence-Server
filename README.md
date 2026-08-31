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