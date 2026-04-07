# Dockerfile
#
# Multi-stage production build for AUROSPACE Orders Demo.
# Non-root user, minimal image, healthcheck included.

# === Stage 1: Base ===
FROM ruby:3.3-slim AS base

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      libpq5 \
      curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_PATH=/usr/local/bundle

# === Stage 2: Build ===
FROM base AS build

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      git \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3 && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

RUN SECRET_KEY_BASE=placeholder bundle exec rails assets:precompile

# === Stage 3: Production ===
FROM base AS production

# Non-root user for security
RUN groupadd --system app && \
    useradd --system --gid app --create-home app

COPY --from=build --chown=app:app /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=app:app /app /app

USER app

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/up || exit 1

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
