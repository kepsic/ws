#!/usr/bin/env python3
import requests
from bs4 import BeautifulSoup
import re

EMHI_URL="http://www.ilmateenistus.ee/ilma_andmed/xml/observations.php"

def format_dict(d):
    for k,v in d.items():
        if re.match('\d+\.\d+',str(v)):
            value=float(v)
        elif re.match('^[-+]?[0-9]+$', str(v)):
            value=int(v)
        else:
            value=v
        d[k]=value
    return d

def emhi_xml(station_name=None):
    """
    Fetch metrics from Estonian Weather Service in xml format and returns it as list of dicts
    """
    soup = BeautifulSoup(requests.get(EMHI_URL, timeout=60).text, 'lxml')
    items=[]
    for item in soup.observations.find_all("station"):
         item_dict={}
         for x in item.find_all():
            item_dict[x.__dict__['name']]=x.text
         items.append(item_dict)
    if station_name:
        items = list(filter(lambda x: re.match(station_name,x['name']),items))
        items = list(map(format_dict, items))
    return items


if __name__ == "__main__":
    print(emhi_xml("Tallinn-Harku")[0])
