FROM python:3.8-slim as build-base

RUN apt update && apt install -y --no-install-recommends gcc make wget python3-dev&& \
    python -m venv --copies --system-site-packages /opt/venv && \
    pip install pip --upgrade
    
ENV PATH="/opt/venv/bin:$PATH"

FROM build-base as intermediate-build

SHELL ["/bin/bash","-c"]

COPY requirements.txt /tmp

RUN cd /tmp && \
    chmod +x /opt/venv/bin/activate && \
    source /opt/venv/bin/activate && pip install -r requirements.txt && \
    find / -name "__pycache__" | xargs rm -fr

FROM python:3.8-slim as release-image

RUN mkdir -p /app/ /app/.kube  /var/log/monitor/ && \
    groupadd -g 1000 appuser && \
    useradd -r -u 1000 -g appuser appuser && \
    chown appuser:appuser -R /app

COPY --chown=appuser:appuser --from=intermediate-build /opt/venv /opt/venv
COPY --chown=appuser:appuser enviar_email.py /app/enviar_email.py
COPY --chown=appuser:appuser vulnerabilidades.py /app/vulnerabilidades.py
COPY --chown=appuser:appuser list_vulns_sonarqube.py /app/list_vulns_sonarqube.py

WORKDIR /app

ENV PATH="/opt/venv/bin:/app:$PATH" \
	TMPDIR="/app"
    
USER appuser

ENTRYPOINT  ["/opt/venv/bin/python", "/app/list_vulns_sonarqube.py"]
CMD ["-h"]
