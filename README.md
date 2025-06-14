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

Run Bandit server:

```bash
mix server
```

Run iex session:

```bash
iex -S mix
```

## TODOs

- [ ] Implement scraping scheduler
- [ ] Better requests
- [ ] Move link handling to a separate module
- [ ] Add more usage of with
- [ ] Add tests
- [ ] Fix link building
- [ ] Fix code structure
- [ ] Add better error handling
- [ ] Implement web UI for starting runs
- [ ] Implement web UI for displaying run graphs
