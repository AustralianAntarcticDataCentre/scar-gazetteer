# Development Notes

## Coastline Map Data

The OpenLayers map embed in the place name page uses coastline data from <https://data.bas.ac.uk/items/93ac35af-9ec7-4594-9aaa-0760a2b289d5>. The GeoJSON file used in the project was created by first downloading the GeoPackage and converting it into GeoJSON using [GDAL](https://gdal.org/en/stable/).

The commands below show how this was achieved on Ubuntu.
```bash
sudo apt install gdal-bin
ogr2ogr -f GeoJSON antarctica.json add_coastline_medium_res_polygon_v7_10.gpkg add_coastline_medium_res_polygon_v7_10
```
---

## JWT/postgrest Issue

There is a problem in that the JWT return from <https://data.aad.gov.au> contains an array of `roles` while postgrest (v9) cannot check for multiple roles for authentication purposes.

To work around this, the AAD token was, during testing, overridden with another one which also contains a singular `role` item. This test token was generated using the script below, based on the one provided in the postgrest documentation at <https://docs.postgrest.org/en/v13/tutorials/tut1.html#step-3-sign-a-token>.

```bash
#!/bin/bash
set -e

JWT_SECRET='secretsecretsecretsecretsecretsecret'

_base64 () { openssl base64 -e -A | tr '+/' '-_' | tr -d '='; }

header=$(echo -n '{"alg":"HS256","typ":"JWT"}' | _base64)

# role required for postgrest authentication
# roles array required for vue authentication
# expires 2030
payload=$(echo -n "{\"role\":\"GAZ_EDIT\", \"roles\":[\"GAZ_EDIT\"], \"user\": {\"username\": \"test\"}, \"iat\":1758248439, \"exp\":1915978831}" | _base64)

signature=$(echo -n "$header.$payload" | openssl dgst -sha256 -hmac "$JWT_SECRET" -binary | _base64)

echo -n "$header.$payload.$signature"
```

Inherited roles were added to the db schema so that `GAZ_EDIT` and the like can act as a `scar_admin`.

---

## Web Image Build

There is an issue where after the build has been successfully (`npm run build`) completed, a connection to `127.0.0.1:80` is attempted, failing the process. A temporary workaround to this is modifying the build script in `package.json` like so: `"build": "vue-cli-service build || true"`. This allows for the web image to be built successfully with Docker compose.

---

## Other

- The project continues the use of node version `14.21.3` (and corresponding npm version `6.14.18`).

- `.env.template` file needs to be copied to `.env` (during deployment) to make the environment variables available for the Docker containers.
