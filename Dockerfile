FROM node:16.18.1 as njs-build
WORKDIR /app
COPY ./pontoon/package*json ./
RUN npm i

COPY ./pontoon/babel.config.json .
COPY ./pontoon/translate/ ./translate 
COPY ./pontoon/tag-admin/ ./tag-admin

RUN npm run build -w translate
RUN npm run build -w tag-admin

FROM python:3.9-bullseye AS server

ENV DEBIAN_FRONTEND=noninteractive
ENV HGPYTHON3=1

ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONPATH /app

WORKDIR /app

# Install Pontoon Python requirements
COPY pontoon/requirements/* /app/requirements/
RUN pip install -U 'pip' && \
    pip install --no-cache-dir --require-hashes -r requirements/default.txt -r requirements/dev.txt -r requirements/test.txt -r requirements/lint.txt

RUN apt-get update \
    && apt-get install -y apt-transport-https \
    && curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        nodejs \
    && apt-get autoremove -y

RUN groupadd -r pontoon --gid=1000 && useradd --uid=1000 --no-log-init -r -m -g pontoon pontoon
RUN chown -R pontoon:pontoon /app

COPY --chown=pontoon:pontoon ./pontoon/ /app/
COPY --chown=pontoon:pontoon --from=njs-build /app/tag-admin/dist /app/tag-admin/dist
COPY --chown=pontoon:pontoon --from=njs-build /app/translate/dist /app/translate/dist
COPY --chown=pontoon:pontoon --from=njs-build /app/translate/public /app/translate/public
COPY --chown=pontoon:pontoon --from=njs-build /app/node_modules /app/node_modules

USER pontoon

ARG SECRET_KEY=non-existing
ARG DATABASE_URL=postgres://pontoon:asdf@postgresql/pontoon

RUN python manage.py collectstatic --no-input
