# pgAdmin 4 – PostgreSQL-Administration mit Beispieldatenbank
 
Eine pgAdmin4-Instanz pro Team mit einer vorinstallierten PostgreSQL-Datenbank (Pagila-Beispieldatensatz). Jedes Team erhält eine eigene VM mit einem dedizierten pgAdmin-Login und direktem Datenbankzugriff.
 
## User-Management
 
Es wird **ein pgAdmin-Account pro Team** erstellt — alle Mitglieder eines Teams teilen sich denselben Login. Die Login-E-Mail hat die Form `<teamname>@example.com`, das Passwort wird automatisch generiert. Zugangsdaten werden nach dem Deployment per Mail an alle Teammitglieder versendet. Der pgAdmin-Account wird direkt in die interne SQLite-Datenbank geschrieben (PBKDF2-SHA512).
 
Die VM enthält außerdem eine lokale PostgreSQL-Instanz mit der **Pagila-Beispieldatenbank** (Film-/Videoverleih-Schema), die im pgAdmin-Account bereits vorkonfiguriert ist. Das Passwort dazu ist "pagila".
 
## VM-Deployment
 
Es wird **eine VM pro Team** deployed. Bei zwei Teams entstehen zwei VMs, jede mit eigener Floating IP und eigenem pgAdmin-Login. Flavor: `gp1.small`.
 
## Deployment-Dauer
 
| Phase | Dauer |

|---|---|

| Packer Image Build (einmalig) | ca. 8–14 Min |

| Terraform Apply | ca. 2–4 Min |

| VM-Boot + cloud-init (User-Anlage, Apache-Start) | ca. 3–6 Min |

| **Gesamt erstmalig** | **ca. 15–25 Min** |
 
Bei vorhandenem Packer-Image entfällt der Build — dann ca. **5–10 Minuten** gesamt.
 
## Konfigurierbare Variablen
 
| Variable | Beschreibung | Pflicht |

|---|---|---|

| `network_uuid` | UUID des internen Netzwerks | Ja (Default vorhanden) |

| `floating_ip_pool` | Name des External Networks für die öffentliche IP | Ja (Default vorhanden) |

| `shared_secgroup_id` | ID der Security Group | Ja (Default vorhanden) |
 
Kein File-Upload. Alle Defaults sind auf die DHBW-OpenStack-Infrastruktur vorkonfiguriert.

 

## Pod-Variante (ab v2.0.0)

Ab Version `v2.0.0` läuft pgAdmin als Pods statt als VMs (`appstore.yaml`, App-Vertrag v2):
**ein Pod pro Team** mit zwei Containern – pgAdmin 4 (per HTTPS-Link erreichbar) und
PostgreSQL mit der Pagila-Beispieldatenbank. Beide teilen sich ein Volume (2 GiB), sodass
Konfiguration und Daten Pause/Fortsetzen und Neustart überstehen. Keine VM, kein
Packer-Build, kein OpenStack-Credential.

- **Login:** ein Account pro Team wie bisher. Benutzername `pgadmin@dhbw.de` (fest), das
  Passwort wird von der Plattform erzeugt und steht unter „Meine Zugänge“.
- **Datenbank:** der Server „pagila (local)“ ist vorkonfiguriert; das Passwort für
  `pagila_user` ist `pagila` (wird beim ersten Verbinden abgefragt).
- **Images:** `image/pgadmin` und `image/postgres` werden von `.github/workflows/image.yml`
  gebaut (inkl. Smoke-Test mit dem Sicherheitskontext der Plattform). Pagila wird beim
  Image-Build geladen, nicht beim Start. Nach einer Änderung die neuen Digests in
  `appstore.yaml` eintragen und eine neue Version taggen.
- Die Versionen `v1.x` (Terraform/Packer) laufen unverändert weiter.
