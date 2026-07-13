# Self-Hosted WoW WotLK Private Server with AI-Powered NPCs

A fully containerized World of Warcraft (3.3.5a) private server built on a custom AzerothCore fork, extended with an autonomous bot ecosystem and a locally-hosted LLM integration that gives NPCs natural, in-character conversational ability.

This project was built from scratch as a personal learning exercise in systems integration, containerization, C++ build troubleshooting, and practical LLM deployment on consumer hardware.

## Stack

- **Core**: AzerothCore (Playerbot fork), C++, CMake
- **Containerization**: Docker / Docker Compose, WSL2
- **Database**: MySQL 8.4
- **AI**: Ollama (local inference), Qwen3 8B (GGUF, Q4_K_M quantization)
- **Scripting**: Lua (custom WoW client addon), SQL
- **Tools**: Keira3 (database GUI editor)

## What this project does

- Runs a fully functional WotLK 3.3.5a server with up to 200 concurrent AI-driven bots (via [mod-playerbots](https://github.com/mod-playerbots/mod-playerbots)) that level, quest, and group autonomously
- Integrates a **local LLM** ([mod-ollama-chat](https://github.com/DustinHendrickson/mod-ollama-chat)) so bots respond to players with dynamically generated, personality-driven dialogue instead of static text
- Adds custom NPCs, vendors, and world content authored directly in the game database
- Ships a small custom WoW addon (Lua) to speed up in-game coordinate capture for content authoring

## Screenshots

**Custom NPC authored via database editing (Keira3), with custom model, vendor and gossip flags**
![Custom NPC](images/custom-npc-alessandro.jpg)

**Server info on login, confirming AzerothCore + AutoBalance + mod-playerbots (100 bots configured)**
![Server boot info](images/server-boot-info.png)

**AI-driven bot dialogue via mod-ollama-chat, staying fully in-character**
![Bot AI conversation](images/bot-chat-ai.png)

## Engineering challenges & how they were solved

This is the part I'm most proud of — the project involved real debugging across several layers of the stack, not just following a guide.

### 1. Diagnosing a C++ compilation failure caused by fork divergence
A community module failed to compile against the custom Playerbot fork with an `override` signature mismatch. Root-caused it to version drift between the module (tracking upstream AzerothCore) and the fork (which lags upstream to support bot-specific hooks) — a common but under-documented class of problem in this ecosystem. Resolved by isolating and removing the incompatible module rather than patching core signatures blindly.

### 2. Docker network isolation between the game server and a host-level service
The worldserver (containerized) needed to reach Ollama (running on the Windows host) over HTTP. Diagnosed a chain of failures: `localhost` inside the container resolving to the container itself, Ollama's default bind to `127.0.0.1` only, and Windows Firewall/OS-level network exposure settings. Solved via `host.docker.internal` routing + explicitly exposing Ollama to the network.

### 3. VRAM-constrained model selection under real load
Benchmarked three local LLMs (Mistral 7B, Qwen3 8B, Qwen 3.5 9B) against an 8GB VRAM budget while the server was concurrently running 100-200 bots. Used `ollama ps` to inspect actual CPU/GPU compute split per model and identified that a larger model spilling ~12% of its layers onto CPU was enough to create system-wide latency, despite looking fine in isolated testing. Reverted to the model that ran 100% on GPU rather than chasing marginal quality gains at the cost of stability.

### 4. Iterative prompt engineering to fix real LLM failure modes
The LLM integration initially exhibited several failure modes typical of small (7-8B) models: breaking character to talk "as a gamer" instead of a world resident, hallucinating in-game lore/locations, forgetting to stay on a new topic after a prior conversation, and inconsistent language switching. Fixed through a structured rewrite of the system prompt and chat templates — including deliberately duplicating key instructions closer to the generation point to exploit the model's recency bias, and restructuring conversation history formatting to clearly separate "past" from "current" context.

### 5. Legacy client scripting under a deprecated API surface
Wrote a small Lua addon for the 2010-era WoW client to streamline in-game coordinate capture. First attempt failed because it used a modern `CreateFrame` template (`BasicFrameTemplate`) that doesn't exist in this client version. Rewrote using native `SetBackdrop` calls, then further reworked the event hook from a specific chat event type to a more robust `AddMessage` hook after the initial event type proved unreliable for parsing server-side GM command output.

## Custom Addon: GPSCopy

A lightweight Lua addon (`addons/GPSCopy/`) that listens for the server's `.gps` command output and surfaces the coordinates in a selectable text box (Ctrl+A, Ctrl+C), removing the need to manually retype coordinates when authoring world content.

## Repository structure

```
├── addons/GPSCopy/          # Custom Lua addon
├── configs/                 # Sanitized module configs (playerbots, ollama-chat, docker-compose overrides)
├── sql/                     # Custom NPC/content SQL
└── docs/                    # Setup notes and troubleshooting log
```

## Notes

This is a personal/educational project. Server credentials, API keys, and any real IPs have been removed or replaced with placeholders in all committed configs. No copyrighted game client files are included in this repository.
