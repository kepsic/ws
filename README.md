# Emon Tallinn weather station
## What it is?

This is a demonstration Observability stack in AZ as IAAC. 
Its collects Tallinn-Harku wheather station metrics into Prometheus and visalises it with Graphana

## How to access

https://tallinn.emon.ee

PS! It's using LE STAGING certificates. 

# Used technology stack

* GitHub for repository
* Terrafrom 0.14
* Ansible
  * Ansible roles
* Docker
* Docker Compose
* Graphana
* Prometheus
* Python


# Requiments
* AZ account
* DuckDNS token
* AZ cli

## How to use it

* Fill the .env file
  ``cp .env_example .env``


* Init terrafrom

    ``./setup --init``


* Plan terrafrom

  ``./setup --plan``


* Apply terrafrom

  ``./setup --commit``


* Destroy terrafrom

  ``./setup --destroy``
