# Drift Beacon

Drift Beacon is an activity tracker. This app runs the Drift Beacon hub on your Home Assistant host. The hub keeps your activities and sessions, serves the web dashboard, and connects the mobile app, the Drift Beacon integration and your other devices.

## Open the dashboard

Start the app and select **Open Web UI**. The dashboard opens over HTTPS, on port 9820 of your Home Assistant host. The first time, your browser warns you about the hub's certificate; accept it to go on (see [the certificate](#the-certificate)). The dashboard then guides you through creating an account and signing in.

Each address you open the dashboard at, such as your host's name or its IP address, keeps its own copy of your data in the browser, and asks you to sign in again. Your data stays on the hub either way. Bookmark one address and use that one.

## Host networking

The app uses your Home Assistant host's network instead of a network of its own. That is why its store page shows a **host** chip, and why its security rating is 4 rather than 5. Discovery and plugins that find devices on your network need the host's network.

## Ports

| Port | What uses it |
| --- | --- |
| 9820, HTTPS | The web dashboard and **Open Web UI** |
| 9821, HTTP | The mobile app, the Drift Beacon integration and your other devices. A browser that opens this port is sent on to the HTTPS port |

To change a port, for example because another app already uses it, set the new one in the **Network** section of the app's **Configuration** tab, save, and restart the app. **Open Web UI** and the watchdog follow the new port. If you change the HTTP port, change it in the mobile app and the Drift Beacon integration too.

The app needs both ports. It doesn't start when either one is empty, or when another program already uses it. Its log then names the port.

## The certificate

The hub makes its own certificate for the dashboard. Each browser asks you to accept it once. Chrome asks again after a week.

To use a certificate of your own instead, put the certificate and its private key in Home Assistant's `/ssl` folder. Then set `certfile` and `keyfile` to their file names in the **Configuration** tab. Set both or neither: with both empty, the hub uses its own certificate.

## Options

| Option | Meaning |
| --- | --- |
| `mdns_hostname` | **Network name.** The hub's name on your network, `driftbeacon` unless you change it. Computers open the dashboard at this name followed by `.local`, on the HTTPS port. Use lowercase letters, digits and hyphens |
| `certfile` | **Certificate file.** A certificate of your own, by its file name in the `/ssl` folder, for example `fullchain.pem`. Leave it empty to use the hub's own certificate |
| `keyfile` | **Private key file.** The private key of that certificate, by its file name in the `/ssl` folder, for example `privkey.pem`. Set both files or neither |
| `trusted_origins` | **Trusted origins.** Other browser addresses allowed to use the hub, comma-separated, for example `https://drift.example.com`. You only need it behind a reverse proxy that rewrites the `Host` header: the hub then refuses its own pages with 403, and its log says `request from a browser page refused`. Listing the public address also admits the mobile app's live connections through that proxy. It takes `http://` and `https://` addresses only, so it can't admit a device that sends another kind of `Origin` (see [troubleshooting](#troubleshooting)) |
| `log_level` | **Log level.** `debug` adds detailed lines to the log, for finding a problem. `info`, the default, is the normal log. Warnings and errors are always logged |

## The Drift Beacon integration

The Drift Beacon integration brings your activities into Home Assistant as devices, entities, triggers and actions. Installing this app doesn't install the integration.

1. Install the integration. In HACS, add `https://github.com/drift-beacon/ha-integration` as a custom repository of the type **Integration**, then download **Drift Beacon**.
2. Restart Home Assistant.
3. In the Drift Beacon dashboard, open your workspace's settings and create a key under **API Keys**.
4. In Home Assistant, go to **Settings → Devices & services**, add **Drift Beacon**, and enter your Home Assistant host's IP address, the HTTP port (9821 unless you changed it) and the key. The integration calls the key an access token.

## Plugins

Plugins add features to the hub, such as controlling your lights. They run separately from the hub, as a user of their own that can't read the hub's data. A plugin gets only what Drift Beacon gives it in the workspaces where you turn it on.

Because the app uses the host's network, plugins can reach the devices on your network. They can also reach other services on your network and on this host, so install only plugins you trust.

## Your data

The hub keeps its data in the app's own storage. Keep that data when you move or restore the app: an activity export alone doesn't hold the hub's accounts, sign-ins, settings and plugins.

Resetting the mobile app on a phone clears only that phone. The hub keeps its data.

## Restart after a failure

Turn on **Watchdog** on the app's Info page. If Drift Beacon stops answering or fails, Home Assistant then restarts it for you. Watchdog is off until you turn it on. Without it, a failed app shows as stopped until you start it again.

## Troubleshooting

| Symptom | What to do |
| --- | --- |
| The app doesn't start, and its log names a port | Another program uses that port, or it is empty in the app's settings. Set a free port in the **Network** section of the **Configuration** tab |
| The app doesn't start, and its log names a certificate file | Clear `certfile` and `keyfile` in the **Configuration** tab, and the hub uses its own certificate again. To keep your own, check that both files are in `/ssl` and belong together |
| **Open Web UI** doesn't show the dashboard | Check that the app is running, and read its log. The dashboard is on HTTPS, on port 9820 unless you changed it in the **Network** section |
| The browser warns about the certificate | With the hub's own certificate, this is expected: accept it. With your own, check that it names the address you open and that your computer trusts it |
| The dashboard asks you to sign in again | You opened it at a different address, and each address signs in on its own. Use the address you bookmarked |
| The dashboard loads but the workspace doesn't | Check that you are signed in with an account that belongs to that workspace |
| Drift Beacon devices in Home Assistant are unavailable | Check the integration's address, port and key. The key may have been deleted in the dashboard |
| A device or script gets 403 when it opens a live connection, and the log says `request from a browser page refused` | Check the `Origin` header its WebSocket library sends. It must send none, or the hub's own address, for example `http://192.168.1.10:9821`. Some libraries send `file://` by default (the Arduino `WebSockets` library does), which the hub refuses. `trusted_origins` can't allow it, so change the client |
| Notifications don't arrive on a phone | Check that the Drift Beacon app may send notifications in the phone's settings, and that it is signed in to this hub |
