# Scraphex

Scraphex is a Elixir app for web scrapping with graph display of scrapped pages.

In the current version, it scraps the title of each page, extracts all relative links, proceeds to scrape those pages, and saves the connections between them.

## Installation

The app is using SQLite by default. You can also switch repo to postgres and start database using docker compose:

```bash
docker-compose up -d
```

Install dependencies and setup database:

```bash
mix setup
```

You should be good to go at this point.

Run the application:

```bash
mix run --no-halt
```

Run iex session:

```bash
iex -S mix
```

## TODOs

UI:

- [ ] Clickable nodes
- [ ] Search nodes
- [ ] Pagination
- [ ] Run stats

Backend:

- [ ] Remove sleep from the tests
- [ ] Make limits configurable
- [ ] Stopped and failed statuses
- [ ] Failed pages

Done:

- [x] Worker tests
- [x] Implement scraping scheduler
- [x] Move link handling to a separate module
- [x] Add tests
- [x] Fix link building
- [x] Fix code structure
- [x] Add better error handling
- [x] Imlement web UI for starting runs
- [x] Implement web UI for displaying run graphs
- [x] Scheduler tests
- [x] Fix link building (again, there are still some absolute/absolute issues)
- [x] Do something about redirects
