# Managed Database Setup

## Create PostgreSQL Database

```bash
./scripts/create-postgres.sh my-db nyc3
```

## Connect to Database

```bash
doctl databases connection <db-id> --format Host,Port,User,Password
```

## Create Connection Pool

```bash
doctl databases pool create <db-id> --name mypool --mode transaction --size 10
```
