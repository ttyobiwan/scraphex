# Scraphex

Elixir web scrapping app, with graph display of scrapped pages.

## Installation

Start Postgres using Docker Compose:

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

- [ ] Fix link building (again, there are still some absolute/absolute issues)
- [ ] Clickable nodes
- [ ] Search nodes
- [ ] Pagination
- [ ] More tests
- [ ] Stopped and failed statuses
- [ ] Failed pages
- [ ] Run stats

- [x] Implement scraping scheduler
- [x] Move link handling to a separate module
- [x] Add tests
- [x] Fix link building
- [x] Fix code structure
- [x] Add better error handling
- [x] Imlement web UI for starting runs
- [x] Implement web UI for displaying run graphs
