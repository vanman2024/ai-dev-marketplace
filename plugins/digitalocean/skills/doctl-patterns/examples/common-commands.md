# doctl CLI Examples

## Authentication

```bash
./scripts/setup-doctl.sh
```

## Common Commands

```bash
# List resources
doctl compute droplet list
doctl apps list
doctl databases list

# Get app logs
doctl apps logs <app-id> --type=run
```
