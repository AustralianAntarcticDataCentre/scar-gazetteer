<template>
    <div>
        <div class="map-controls mb-2">
            <b-button-group size="sm">
                <b-button :variant="mapProjection === 'EPSG:3031' ? 'primary' : 'outline-primary'"
                    @click="changeProjection('EPSG:3031')">
                    Polar Stereographic
                </b-button>
                <b-button :variant="mapProjection === 'EPSG:4326' ? 'primary' : 'outline-primary'"
                    @click="changeProjection('EPSG:4326')">
                    Mercator
                </b-button>
            </b-button-group>
        </div>
        <div ref="map" class="map-container"></div>
    </div>
</template>

<script>
import Feature from 'ol/Feature';
import GeoJSON from 'ol/format/GeoJSON';
import Map from 'ol/Map';
import Point from 'ol/geom/Point';
import VectorLayer from 'ol/layer/Vector';
import VectorSource from 'ol/source/Vector';
import View from 'ol/View';
import { Style, Fill, Stroke, Icon } from 'ol/style';
import 'ol/ol.css';

import proj4 from "proj4";

// https://epsg.io/3031
proj4.defs("EPSG:3031", "+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +type=crs")

const landStyle = new Style({
    fill: new Fill({
        color: '#f8f8f8',
    }),
    stroke: new Stroke({
        color: '#333333',
        width: 0.3
    }),
});

const iceStyle = new Style({
    fill: new Fill({
        color: '#e9ecef',
    }),
    stroke: new Stroke({
        color: '#333333',
        width: 0.3
    }),
});

const mapStyle = function (feature) {
    const isLand = feature.get('surface') == 'land';
    return isLand ? landStyle : iceStyle;
}

const antarcticaLayer = new VectorLayer({
    source: new VectorSource({
        format: new GeoJSON(),
        url: '/data/antarctica.json',
        attributions: 'Data provided by SCAR ADD (As part of BAS Data Catalogue)',
    }),
    style: mapStyle
});

const worldLayer = new VectorLayer({
    source: new VectorSource({
        format: new GeoJSON(),
        url: '/data/world.json',
        attributions: "Data provided by Natural Earth",
    }),
    style: mapStyle
});

const polarStereographicView = new View({
    center: [0, 0],
    zoom: 4,
    maxZoom: 10,
    extent: [-5000000, -5000000, 5000000, 5000000],
    constrainOnlyCenter: false
})

const mercatorView = new View({
    center: [0, -10018754], // -75° latitude in Web Mercator
    zoom: 0,
    maxZoom: 8,
})

export default {
    props: {
        coordinates: {
            type: Object,
            required: true,
        },
    },
    data: () => ({
        map: null,
        mapProjection: "EPSG:3031",
        markerSource: new VectorSource(),
    }),
    methods: {
        changeProjection(newProjection) {
            if (this.map && newProjection !== this.mapProjection) {
                this.mapProjection = newProjection

                const layers = this.map.getLayers();
                layers.clear();

                if (this.mapProjection === "EPSG:3031") {
                    this.map.setView(polarStereographicView)
                    layers.push(antarcticaLayer)
                } else {
                    this.map.setView(mercatorView)
                    layers.push(worldLayer)
                }

                layers.push(this.markerLayer())
                this.updateMarker()
            }
        },
        updateMarker() {
            this.markerSource.clear();

            if (this.coordinates && typeof this.coordinates?.longitude === 'number' && typeof this.coordinates?.latitude === 'number') {
                let markerFeature = null;

                if (this.mapProjection === "EPSG:3031") {
                    markerFeature = new Feature({
                        // 4326 is standard, unprojected coordinate system
                        // 3031 is Antarctic Polar Stereographic
                        geometry: new Point(proj4("EPSG:4326", "EPSG:3031", [this.coordinates.longitude, this.coordinates.latitude]))
                    });
                } else {
                    markerFeature = new Feature({
                        // 3857 is Web Mercator
                        geometry: new Point(proj4("EPSG:4326", "EPSG:3857", [this.coordinates.longitude, this.coordinates.latitude]))
                    });
                }

                this.markerSource.addFeature(markerFeature);
            } else {
                console.error("Invalid coordinates")
            }
        },
        markerLayer() {
            return new VectorLayer({
                source: this.markerSource,
                style: new Style({
                    image: new Icon({
                        anchor: [0.5, 1],
                        scale: 0.02,
                        src: '/static/marker.svg'
                    })
                })
            });
        }
    },
    watch: {
        coordinates() {
            this.updateMarker()
        }
    },
    mounted() {
        this.map = new Map({
            target: this.$refs.map,
            layers: [
                antarcticaLayer,
                this.markerLayer(),
            ],
            view: polarStereographicView
        })

        this.updateMarker()
    }
}
</script>

<style>
.map-container {
    border: 1px solid var(--bs-dark);
    height: 500px;
    background-color: #8bcfef;
}
</style>