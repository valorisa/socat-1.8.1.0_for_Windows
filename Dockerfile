# syntax=docker/dockerfile:1

ARG PYTHON_VERSION=3.14.2
FROM python:${PYTHON_VERSION}-slim as base

# Prévenir l'écriture des fichiers pyc
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Installer les outils nécessaires, y compris socat, curl, wget, et bash
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    build-essential \
    libssl-dev \
    socat \
    bash \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Installer une version spécifique de socat (1.8.1.0)
ARG SOCAT_VERSION=1.8.1.0
RUN wget http://www.dest-unreach.org/socat/download/socat-${SOCAT_VERSION}.tar.gz && \
    tar -xzf socat-${SOCAT_VERSION}.tar.gz && \
    cd socat-${SOCAT_VERSION} && \
    ./configure && \
    make && \
    make install && \
    cd .. && \
    rm -rf socat-${SOCAT_VERSION} socat-${SOCAT_VERSION}.tar.gz

# Créer un utilisateur non privilégié 'valorisa' avec bash comme shell par défaut
ARG VALORISA_UID=10002
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/bin/bash" \
    --no-create-home \
    --uid "${VALORISA_UID}" \
    valorisa

# Copier le fichier requirements.txt et installer les dépendances Python
COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install --no-cache-dir -r requirements.txt

# Copier le code source de l'application
COPY . .

# Exposer le port utilisé par l'application
EXPOSE 8181

# Par défaut, utiliser l'utilisateur root
USER root

# Lancer l'application avec l'utilisateur 'valorisa'
CMD ["bash", "-c", "exec su valorisa -c 'gunicorn socat.example:app --bind=0.0.0.0:8181'"]

