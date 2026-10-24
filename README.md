# pgAdmin 4 – PostgreSQL-Administration mit Beispieldatenbank

Eine pgAdmin4-Instanz pro Team mit einer vorinstallierten PostgreSQL-Datenbank (Pagila-Beispieldatensatz). Jedes Team erhält einen eigenen Pod mit einem dedizierten pgAdmin-Login und direktem Datenbankzugriff.

Die App läuft als Pods (`appstore.yaml`, App-Vertrag v2): **ein Pod pro Team** mit zwei Containern – pgAdmin 4 (per HTTPS-Link erreichbar) und PostgreSQL mit der Pagila-Beispieldatenbank. Beide teilen sich ein Volume (2 GiB), sodass Konfiguration und Daten Pause/Fortsetzen und Neustart überstehen.

## User-Management

Es wird **ein pgAdmin-Account pro Team** erstellt – alle Mitglieder eines Teams teilen sich denselben Login.

- **Login:** Benutzername `pgadmin@dhbw.de` (fest), das Passwort wird von der Plattform erzeugt und steht unter „Meine Zugänge“.
- **Datenbank:** der Server „pagila (local)“ (Film-/Videoverleih-Schema) ist im pgAdmin-Account vorkonfiguriert; das Passwort für `pagila_user` ist `pagila` (wird beim ersten Verbinden abgefragt).

## Konfigurierbare Variablen

Keine. Kein File-Upload, alle Einstellungen stehen in `appstore.yaml`.

## Images und CI

`image/pgadmin` und `image/postgres` werden von `.github/workflows/ci.yml` gebaut (zentrale Pipeline aus `app-registry`: Vertrag, hadolint, Smoke-Test, Trivy) und mit dem Sicherheitskontext der Plattform getestet (UID 1000, Read-only-Root, keine Capabilities; `.github/smoke-test-pgadmin.sh`, `.github/smoke-test-postgres.sh`).

- **Pull Request:** die Images werden gebaut und getestet, aber nicht veröffentlicht.
- **Push auf `main` oder `dev`:** die Images werden zusätzlich nach GHCR gepusht. Den Digest zeigt die Zusammenfassung des Jobs.
- Pagila wird beim Image-Build geladen, nicht beim Start.
- Nach einer Änderung an einem Image den neuen Digest in `appstore.yaml` eintragen und eine neue Version taggen. Die Plattform deployt nur Images, die per Digest festgelegt sind.

## Ältere Versionen

Die VM-Versionen (`v1.x`, Terraform und Packer) wurden aus dem Repository entfernt. Sie bleiben über ihre Git-Tags (z. B. `v1.0.0`) abrufbar.
