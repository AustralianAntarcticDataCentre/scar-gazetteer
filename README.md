# SCAR Gazetteer

Vue.js Web Application for the [SCAR Composite Gazetteer of Antarctica](placenames.aq).

This web app is created with Vue.js, Postgrest, and Postgresql.

## Local development
1. Duplicate `.env.example` to `.env`. Fill in the `DATABASE_PASSWORD` property with a random value.
2. Run `docker compose up` to create the Postgres and PostgREST containers. This will also setup the DB schema.
3. Run `npm install` and then `npm run dev`.
4. Application will be available at [http://localhost:5173](http://localhost:5173).

## Local database access
Docker will allocate a random port to the Postgres container each time it is started. You can find the port by running `docker ps` and looking for the `scar-gazetteer-db-1` container. It will show a port mapping similar to `0.0.0.0:32770->5432/tcp` where `32770` is the host port. Use this to connect from any local DB GUI applications or command-line tools.

## Importing data
To import data from a local SQL file use `psql -h 127.0.0.1 -p {port} -U postgres -f ./path/to/file.sql`.

## License
Copyright Commonwealth of Australia. Released under MIT License.
