# README

Orpheus and Heidi after stardance have journeyed on a rocket to a far off moon but to find. Oh No, it is missing the other half. They need to complete the moon to make the sky whole once more. And need your help!

Built on Ruby 4.0.7
Half-Moon is Draft YSWS where:

1. You find a buddy to partner with
2. You each make a project
3. You swap projects
4. You Earn Moondust
5. Rebuild the moon and get prizes!!

## Deployment instructions
~ Needs [Docker](https://www.docker.com/) for easy run
1. Run `docker pull ghcr.io/acidicts/halfmoon:latest`
	If github needs authentication do:
	```
	echo "$GITHUB_TOKEN" | docker login ghcr.io -u <your username> --password-stdin
	docker pull ghcr.io/acidicts/halfmoon:latest
	```
2. Download [.env.example](/.env.example)
3. Rename `.env.example` to `.env`
4. Create a docker compose file eg:
	docker-compose.yml:
	```
	services:
	  web:
	    image: ghcr.io/acidicts/halfmoon:latest
	    env_file:
	      - .env
	    environment:
	      RAILS_ENV: production
	      RACK_ENV: production
	      DB_HOST: db
	      DB_PORT: 5432
	      DB_USERNAME: postgres
	      DB_PASSWORD: postgres
	      REDIS_URL: redis://redis:6379/0
	      PORT: 3000
	    ports:
	      - "3000:3000"
	    depends_on:
	      db:
	        condition: service_healthy
	      redis:
	        condition: service_started
	    restart: unless-stopped
	
	  db:
	    image: postgres:17
	    environment:
	      POSTGRES_USER: postgres
	      POSTGRES_PASSWORD: postgres
	      POSTGRES_DB: production
	    volumes:
	      - postgres_data:/var/lib/postgresql/data
	    healthcheck:
	      test: ["CMD-SHELL", "pg_isready -U postgres -d granitemd_production"]
	      interval: 5s
	      timeout: 5s
	      retries: 10
	
	  redis:
	    image: redis:7-alpine
	    volumes:
	      - redis_data:/data
	
	volumes:
	  postgres_data:
	  redis_data:
	```
4. Start the application with `docker compose up -d`

Alternatively if you already have a postgres and redis instance you can do:
```
docker run --rm \
  --name issued \
  --env-file .env \
  -e DB_HOST=your-postgres-host \
  -e DB_PORT=5432 \
  -e DB_USERNAME=postgres \
  -e DB_PASSWORD=your-password \
  -e REDIS_URL=redis://your-redis-host:6379/0 \
  -p 3000:3000 \
  ghcr.io/acidicts/granitemd:latest
```


### Credits
- Font - Matcha Style - https://www.dafont.com/matcha-style.font
- Font - Starborn - https://www.dafont.com/starborn.font
