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

- [ ] Pagination
- [ ] Stopped and failed statuses
- [ ] Failed pages
- [ ] Imlement web UI for starting runs
- [ ] Implement web UI for displaying run graphs
