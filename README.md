# Scraphex

Elixir web scrapping app, with graph display of scrapped pages.

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

- [ ] Clickable nodes
- [ ] Search nodes
- [ ] Pagination
- [ ] Stopped and failed statuses
- [ ] Failed pages
- [ ] Run stats
- [ ] Remove sleep from the tests
- [ ] Make limits configurable

- [ ] Fix link building (again, there are still some absolute/absolute issues)

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
