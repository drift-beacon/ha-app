# Drift Beacon add-on

This add-on runs the Drift Beacon hub on your Home Assistant host. It stores activities and sessions and connects web, mobile, and automation clients.

## Open the dashboard

Start the add-on and open HTTPS on port 9000 of your Home Assistant host. The add-on also exposes HTTP on port 9001. If you disable SSL, use the HTTP address directly; the Open Web UI shortcut may still select port 9000.

Port mappings are configured in the add-on's Network settings. There is no `port` configuration option.

## Options

| Option | Meaning |
| --- | --- |
| `ssl` | Enable HTTPS on port 9000; defaults to true |
| `certfile` | Certificate filename in the `/ssl` share; defaults to `fullchain.pem` |
| `keyfile` | Private-key filename in the `/ssl` share; defaults to `privkey.pem` |
| `trusted_origins` | Extra browser origins allowed to use the hub, comma-separated (for example `https://drift.example.com`). Only needed behind a reverse proxy that rewrites `Host`; empty by default |

When either configured certificate file is missing, the add-on creates or reuses a self-signed certificate in its persistent data directory. Clients may show a certificate warning. Use a certificate trusted by your clients when they require certificate verification.

The HTTP listener remains available when SSL is enabled and does not redirect to HTTPS. On hosts with IPv6 support, both address families have listeners.

## Data and integration

The hub persists its data under the add-on's `/data` directory. Preserve this data when moving or restoring the add-on; an activity export does not include all hub identity, authentication, and server state.

The Home Assistant custom integration is installed separately. It connects to the hub with a workspace-scoped access token to expose devices, entities, and actions. Installing this add-on alone does not install the integration.

To use Drift Beacon from Home Assistant (devices, actions, triggers), install the [Drift Beacon integration](https://github.com/drift-beacon/ha-integration).
