---
hide:
  - navigation
---

# Frequently Asked Questions

## How Is Popcorn Pronounced?

Popcorn is pronounced like the snack: _pop-korn_.

## What Is A `.pop` File?

A `.pop` file is a text-based popcast recording. It stores timestamped terminal
events instead of pixels, which keeps recordings small and lets players render
the terminal at the viewer's size and pixel density.

## Do I Need A Server?

No. You can record, replay, and render `.pop` files locally:

```bash
popcorn rec demo.pop
popcorn play demo.pop
popcorn-gif demo.pop demo.gif
```

Use a server only when you want hosted sharing, live streaming, account-based
management, or API-backed automation.

## Is There A Public Popcorn Hosting Service?

Not yet. Treat Popcorn as source-first and self-hosted until a public service is
announced. Server examples use `https://popcorn.example.com` or
`https://popcorn.example.com` as placeholders; replace them with your own server URL.

## Can I Embed A Recording Without Uploading It?

Yes. Serve the `.pop` file yourself and initialize the browser player on your
page:

```javascript
PopcornPlayer.create('/demo.pop', document.getElementById('demo'));
```

## Can Recordings Contain Secrets?

Yes. Recordings can include terminal output, commands, prompts, paths, hostnames,
and captured input when input capture is enabled. Review recordings before
sharing and avoid recording sensitive sessions.

## Which Format Should New Tools Target?

New tools should target popcast v3 and use `.pop` filenames. Older v1/v2 formats
are documented for compatibility and migration.
