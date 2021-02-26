# VECTOR TILES - SAMPLE DOCKER STACK

**Please do not use this as is in a production environment!  
There are some sample database users that are being created by the steps below 
with passwords that are hardcoded in this repo!**

This is a geopreview sample stack based on the one used in [HDX](https://data.humdata.org/)

## Requirements
* docker - tested on version *20.10* , should work with *>17.04*
* docker-compose - tested on version *1.25.5* , should work with *>1.11.2*

NOTE: this was tested with Docker for Linux and Mac.

## Introduction 
This will create a total of 3 containers.

1. postgis - This is the container that runs the postgres database. The actual database files are mapped outside the container as explained further below.
1. gisapi - This is the NodeJS application that actually serves that vector tiles / PBF. It's based on [gisrestapi](https://github.com/OCHA-DAP/gisrestapi) which in turn was forked from https://github.com/spatialdev/PGRestAPI and slightly modified.
1. ogr2ogr - This is a container that has everything needed to run the *ogr2ogr* command line tool. The container's image was actually created to hold a python application that manages/runs the transformations so it contains additional software not actually needed for this example.

The gisapi server comes with a way of viewing the geodata from postgis as vector tile layers (described below). 
To use the vector tiles / PBF in a separate web application with Leaflet we used the following plugin: https://github.com/SpatialServer/Leaflet.MapboxVectorTile

## Steps to get the stack up

1. Clone this git repo
  `git clone https://github.com/alexandru-m-g/vector-tiles-sample.git` 
  and enter the newly created folder `cd vector-tiles-sample`
  
1. Start the docker stack 
   `docker-compose up -d`
   
1. Initialize the database, **only needed the first time**. A persistent folder called *postgis*
   was created in the current folder where the database files will be stored. 
   The path for this folder is specified in [.env](.env)
   
   `cat postgis/create.sql | docker-compose exec -T postgis psql -U postgres`
   
   Alternatively, you can run
   `docker-compose exec postgis psql -U postgres` and copy paste the lines from [create.sql](postgis/create.sql)
   
   NOTE: this creates a postgres user and database 
   
1.  Restart the *gisapi* container so that it can connect to the newly created postgis db, **only needed the first time**  
    `docker-compose restart gisapi`
   
1.  Import sample shapefile and geojson file into postgis. The *ogr2ogr/samples* folder in this
    project is mapped inside the *ogr2ogr* container and already contains 2 samples: 1 (unzipped) shapefile and 1 geojson. 
    
    In order to run the examples below you will need to be inside the *ogr2ogr* container:  
    ```bash
    # get a shell inside the container
    docker-compose exec ogr2ogr /bin/sh
    ```
    
    Example 1, shapefile:
    ```bash
    # run the import from inside the container
    ogr2ogr --config PG_USE_COPY NO -f "PostgreSQL" "PG:host=postgis dbname=testdb port=5432 user=test password=test" /srv/samples/sample_adm3.shp -nln sample_adm3_shp -overwrite -lco OVERWRITE=YES -fieldTypeToString Real -t_srs EPSG:4326
    ```
    
    Example 2, geojson:
    ```bash
    # run the import from inside the container
    ogr2ogr --config PG_USE_COPY NO -f "PostgreSQL" "PG:host=postgis dbname=testdb port=5432 user=test password=test" /srv/samples/sample.geojson -nln sample_geojson -overwrite -lco OVERWRITE=YES -fieldTypeToString Real -t_srs EPSG:4326
    ```
    
    Example 3, shapefile:
    ```bash
    # run the import from inside the container
    ogr2ogr --config PG_USE_COPY NO -f "PostgreSQL" "PG:host=postgis dbname=testdb port=5432 user=test password=test" /srv/samples/sample_adm1.shp -nln sample_adm1_shp -overwrite -lco OVERWRITE=YES -fieldTypeToString Real -t_srs EPSG:4326 -nlt MultiPolygon
    ```
    
    To try additional files one could just add them in the *ogr2ogr/samples* folder. 
    Please note that the **zipped shapefiles need to be unzipped** before running the 
    *ogr2ogr* import command.
    
 1. See the newly imported layers as vector tiles in a browser. 
 
    **You might neeed to restart the gisapi container for the new tables to show up, see (4). This would not be needed if you'd try to directly access the PBF URLs**
    
    Go to [http://localhost:8888/services/tables](http://localhost:8888/services/tables) and click on the table name 
    that you would like to see. This will load a page with information about the selected table. In order to view the 
    vector tiles based map, click on the "Dynamic Vector Tile Service - wkb_geometry column" link.
 
 
## Other notes
 
The above *ogr2ogr* commands might not work on all shapefiles, geojson, etc. Othere command line arguments that could 
be useful are:
*   specifying MultiPolygon geometry type: `-nlt MultiPolygon`
*   specifying MultiLineString geometry type: `-nlt MultiLineString`
*   I haven't tested this, but it seems like ogr2ogr can automatically enable the above 2 options by using 
    `-nlt PROMOTE_TO_MULTI`.
    From the [ogr2ogr docs](https://gdal.org/programs/ogr2ogr.html) 
    "PROMOTE_TO_MULTI can be used to automatically promote layers that mix polygon or multipolygons 
    to multipolygons, and layers that mix linestrings or multilinestrings to multilinestrings"    
*   forcing source SRS: `-s_srs EPSG:4326`
    
