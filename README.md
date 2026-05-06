# Kernel Docker Sandbox Mixin

This repo contains a [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/) (`sbx`) mixin kit for [Kernel](https://www.kernel.sh). It gives an agent sandbox Kernel tooling, Kernel skills for Claude Code, and proxy-managed Kernel API authentication without putting your real `KERNEL_API_KEY` inside the sandbox.

## Quickstart

### 1. Install Docker Sandboxes

Install and sign in to `sbx` using the [Docker Sandboxes getting started guide](https://docs.docker.com/ai/sandboxes/get-started/).

### 2. Set Up Kernel

Create or use a Kernel account at [kernel.sh](https://www.kernel.sh), then create an API key.

Export the key in the host shell where you run `sbx`:

```bash
export KERNEL_API_KEY=...
```

The real key stays on the host. This kit configures the `sbx` proxy so Kernel API requests from inside the sandbox receive the right auth header.

### 3. Set Up Claude

The built-in Claude sandbox needs Anthropic credentials. Export your API key in the same host shell:

```bash
export ANTHROPIC_API_KEY=...
```

### 4. Launch Claude With Kernel

Start Claude with this mixin:

```bash
sbx run --name kernel-demo --kit . claude -- "Using the Kernel CLI, which is already authenticated, create a browser and navigate to news.ycombinator.com. Tell me the top five articles."
```

The agent should be able to call `kernel` and efficiently complete the task using the installed Kernel skills inside the sandbox without seeing the real `KERNEL_API_KEY`.

## What The Mixin Does

The mixin installs Kernel's CLI:

```yaml
commands:
  install:
    - command: "npm install -g @onkernel/cli"
```

It also installs all agent skills from [`kernel/skills`](https://github.com/kernel/skills):

```yaml
commands:
  install:
    - command: "DISABLE_TELEMETRY=1 npm_config_update_notifier=false npx -y skills add kernel/skills --skill '*' --agent claude-code --global --copy --yes && rm -rf \"$HOME/.agents/skills\" && mkdir -p \"$HOME/.agents\" && cp -a \"$HOME/.claude/skills\" \"$HOME/.agents/skills\""
      user: "1000"
```

Those flags make the `skills` install noninteractive: select all skills, target Claude Code, install globally into the sandbox agent user's home, copy files instead of symlinking, and accept prompts. After the CLI install, the command copies the resulting `~/.claude/skills` tree to `~/.agents/skills` so agents that read the generic skills location can use the same Kernel skills.

It allows the package registry, GitHub, skills metadata, and Kernel API:

```yaml
network:
  allowedDomains:
    - "registry.npmjs.org:443"
    - "github.com:443"
    - "api.github.com:443"
    - "raw.githubusercontent.com:443"
    - "release-assets.githubusercontent.com:443"
    - "add-skill.vercel.sh:443"
    - "skills.sh:443"
    - "api.onkernel.com:443"
```

It maps `api.onkernel.com` to a host-side credential source named `kernel`:

```yaml
credentials:
  sources:
    kernel:
      env:
        - KERNEL_API_KEY
```

The proxy injects the API key as an authorization header for Kernel API requests:

```yaml
network:
  serviceDomains:
    api.onkernel.com: kernel
  serviceAuth:
    kernel:
      headerName: Authorization
      valueFormat: "Bearer %s"
```

