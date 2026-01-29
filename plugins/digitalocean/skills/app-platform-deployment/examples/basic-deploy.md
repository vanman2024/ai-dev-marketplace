# App Platform Deployment Example

## Deploy from GitHub

```bash
./scripts/deploy-from-github.sh my-app https://github.com/user/repo main
```

## Deploy Static Site

```bash
./scripts/deploy-static.sh my-site ./dist
```

## Check Deployment Status

```bash
doctl apps list
doctl apps logs <app-id>
```
