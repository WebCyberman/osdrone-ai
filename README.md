# OSDrone-AI

Drone autonome expérimental pour OpenSimulator.

OSDrone-AI est une plateforme de recherche et d'expérimentation dédiée à la navigation autonome dans OpenSimulator. Le projet combine des scripts LSL embarqués, un serveur FastAPI, un tableau de bord de supervision en temps réel et des composants IA évolutifs.

---

# Fonctionnalités

- Navigation autonome
- Patrouille aléatoire
- Détection des avatars
- Approche et inspection
- Évitement d'obstacles
- Télémétrie temps réel
- Dashboard Web temps réel
- Cartographie de région
- Affichage MOAP dans OpenSimulator
- Commandes distantes
- Historique des trajectoires

---

# Architecture

```text
OpenSimulator
    │
    ▼
AgentBridge.lsl
    │
 HTTP / JSON
    │
    ▼
OSDrone-AI
(FastAPI)
    │
    ├── Dashboard Web
    ├── Carte cognitive
    ├── API REST
    └── IA (future)
```

---

# Modules

## AgentBridge.lsl

Passerelle de communication :

- Envoi de la télémétrie
- Réception des commandes
- Événements OpenSimulator
- Communication HTTP avec FastAPI

## FlightController.lsl

Contrôle du drone :

- Navigation
- Détection d'avatars
- Évitement d'obstacles
- Gestion des missions
- Modes PATROL, APPROACH, SCAN et MANUAL

## FastAPI

Services serveur :

- API REST
- Dashboard Web
- Cartographie temps réel
- Gestion des événements

## Carte cognitive

Mémoire spatiale simplifiée :

- Carte de la région
- Historique des déplacements
- Objectifs actifs

---

# Installation

## Prérequis

- Python 3.11 ou supérieur
- OpenSimulator
- Git

## Clonage du projet

```bash
git clone https://github.com/WebCyberman/OSDrone-AI.git

cd OSDrone-AI
```

## Création d'un environnement virtuel

### Linux

```bash
python3 -m venv venv

source venv/bin/activate
```

### Windows

```powershell
python -m venv venv

venv\Scripts\activate
```

## Installation des dépendances

```bash
pip install -r requirements.txt
```

---

# Lancement en développement

```bash
uvicorn main:app \
    --host 0.0.0.0 \
    --port 8000 \
    --reload
```

Accès :

```text
http://localhost:8000
```

---

# Déploiement Docker

## Construction

```bash
docker compose build
```

## Démarrage

```bash
docker compose up -d
```

## Vérification

```bash
docker ps
```

Accès :

```text
http://<adresse-ip>:8000
```

---

# Structure du projet

```text
OSDrone-AI/

├── main.py
├── requirements.txt
├── docker-compose.yml
├── Dockerfile
│
├── static/
│   ├── app.js
│   ├── style.css
│   └── images/
│
├── templates/
│   └── index.html
│
├── lsl/
│   ├── AgentBridge.lsl
│   └── FlightController.lsl
│
└── data/
```

---

# Feuille de route

## World Model

- Mémoire spatiale persistante
- Cartographie enrichie
- Zones d'intérêt

## JEPA

- Compréhension de l'environnement
- Raisonnement spatial
- Anticipation d'événements
- Planification de missions

## Multi-drones

- Coordination d'agents
- Missions collaboratives
- Carte cognitive partagée

---

# Développement

Les contributions sont les bienvenues.

Pour développer :

```bash
git checkout -b ma-fonctionnalite
```

Puis :

```bash
git commit -m "Ajout de ma fonctionnalité"
```

Enfin :

```bash
git push origin ma-fonctionnalite
```

et ouvrir une Pull Request.

---

# Licence

Projet expérimental de recherche consacré à l'autonomie des agents virtuels dans OpenSimulator.
