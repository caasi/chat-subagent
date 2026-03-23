# blogspot

A Claude Code skill for fetching content from Blogspot/Blogger sites that resist normal `WebFetch` due to JS rendering.

## What it does

- Bypasses JS-rendered Blogspot pages by using the Blogger JSON Feed API directly
- Provides the feed URL template, query parameters, and response structure
- Covers pagination (`start-index`), date filtering, and per-request limits

## When to use

When you need to read, search, or extract content from any `*.blogspot.com` or `*.blogger.com` site. Normal `WebFetch` on Blogspot HTML pages returns an empty shell because the content is JS-rendered.

## Usage

This skill activates automatically when you mention a Blogspot/Blogger URL or ask Claude to fetch blog content. No slash command needed.

## Feed URL

```
https://<blog>.blogspot.com/feeds/posts/default?alt=json&max-results=<n>
```

Key parameters: `max-results` (up to 150 per page), `start-index` (1-based offset), `published-min` / `published-max` (ISO 8601 date filters).

## Response structure

```
feed.entry[]        — array of posts
  .title.$t         — post title
  .content.$t       — full HTML content
  .published.$t     — publish date (ISO 8601)
  .link[]           — links (rel="alternate" for the post URL)
```

## Install

```bash
claude plugin marketplace add caasi/dong3
claude plugin install fetch-tips@caasi-dong3
```

## License

MIT
