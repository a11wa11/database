FROM postgres:17

ENV POSTGRES_USER=testuser
ENV POSTGRES_PASSWORD=testpass
ENV POSTGRES_DB=testdb

COPY init.sql /docker-entrypoint-initdb.d/

EXPOSE 5432
