# Kernel kit for Docker Sandboxes

This mixin gives any [Docker Sandbox](https://docs.docker.com/ai/sandboxes/) agent access to [Kernel](https://www.kernel.sh/) cloud browsers. It installs the Kernel CLI, adds a quick-reference guide, permits the required network destinations, and keeps the Kernel API key outside the sandbox.

Docker publishes the kit at [`docker.io/sbx/kernel-kit`](https://hub.docker.com/r/sbx/kernel-kit) from the [`docker/sbx-kits-contrib`](https://github.com/docker/sbx-kits-contrib/tree/main/kernel) repository.

## Use the published kit

1. Install Docker Sandboxes and sign in by following Docker's [getting started guide](https://docs.docker.com/ai/sandboxes/get-started/).
2. Create a Kernel API key, then store it in Docker Sandboxes' host-side secret store:

   ```console
   sbx secret set kernel
   ```

3. Launch an agent with the kit:

   ```console
   sbx run claude --kit docker.io/sbx/kernel-kit:latest
   ```

On first use, `sbx` asks you to approve injecting the `kernel` credential into requests to `api.onkernel.com`. The sandbox receives only a `proxy-managed` sentinel; the host proxy replaces it with the real key when the request leaves the sandbox.

## Develop locally

Validate and inspect the kit before creating a sandbox:

```console
sbx kit validate .
sbx kit inspect .
```

Run the non-destructive checks with:

```console
scripts/smoke.sh
```

Run the full smoke test with a disposable Claude sandbox after storing the Kernel credential:

```console
scripts/smoke.sh --create
```

The full test verifies the CLI, bundled quick-reference guide, proxy-managed environment variable, and an authenticated Kernel API request. Set `KEEP_SANDBOX=1` to retain the sandbox for debugging.

## Publish an organization-owned copy

Docker Hub publication uses an OCI artifact rather than a container image:

```console
sbx login
sbx kit validate .
sbx kit push . docker.io/onkernel/kernel-kit:latest --sign
```

The Docker Verified Publisher badge is granted at the Docker Hub namespace level. Pushing a kit does not grant the badge; the `onkernel` namespace must complete Docker's [Verified Publisher application](https://hub.docker.com/publisher-program/apply) separately.

## Kit contents

- `spec.yaml` — schema v2 mixin definition
- `files/home/.kernel/quickstart.md` — examples installed into the agent's home directory
- `scripts/smoke.sh` — local validation and optional end-to-end test
