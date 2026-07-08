# Integrations

Popcorn exposes a few stable integration surfaces:

- `.pop` / popcast files for recording interchange,
- the browser player for web embeds,
- `popcorn-gif` for GIF rendering,
- the server HTTP API for upload, metadata, and stream management,
- WebSocket live-stream endpoints for producers and consumers.

## Websites And Docs

Use [popcorn player](manual/player/index.md) when you can serve JavaScript and
CSS alongside a `.pop` file. This preserves text selection, copy/paste,
playback controls, themes, markers, speed controls, and crisp rendering.

Use [popcorn-gif](manual/popcorn-gif/index.md) when the destination only accepts
images.

## Hosting And Automation

Use the [server API](manual/server/api.md) to upload recordings, update
metadata, create live streams, and delete resources. Use a self-hosted server
URL in examples:

```bash
export POPCORN_API_URL=https://popcorn.example.com
popcorn upload demo.pop
```

## Compatibility

New integrations should use Popcorn names, `.pop` files, and the current
popcast v3 format.
