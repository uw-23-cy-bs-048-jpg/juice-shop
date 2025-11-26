FROM node:22 AS installer
COPY . /juice-shop
WORKDIR /juice-shop

RUN npm i -g typescript ts-node
RUN npm install --omit=dev
RUN npm dedupe --omit=dev

RUN rm -rf frontend/node_modules
RUN rm -rf frontend/.angular
RUN rm -rf frontend/src/assets

RUN mkdir logs
RUN chown -R 65532 logs
RUN chgrp -R 0 ftp/ frontend/dist/ logs/ data/ i18n/ || true
RUN chmod -R g=u ftp/ frontend/dist/ logs/ data/ i18n/ || true

RUN rm data/chatbot/botDefaultTrainingData.json || true
RUN rm ftp/legal.md || true
RUN rm i18n/*.json || true

ARG CYCLONEDX_NPM_VERSION=latest
RUN npm install -g @cyclonedx/cyclonedx-npm@$CYCLONEDX_NPM_VERSION
RUN npm run sbom

FROM gcr.io/distroless/nodejs22-debian12
ARG BUILD_DATE
ARG VCS_REF

LABEL maintainer="Bjoern Kimminich <bjoern.kimminich@owasp.org>" \
    org.opencontainers.image.title="OWASP Juice Shop"

WORKDIR /juice-shop

COPY --from=installer --chown=65532:0 /juice-shop .

USER 65532
EXPOSE 3000
CMD ["/juice-shop/build/app.js"]

