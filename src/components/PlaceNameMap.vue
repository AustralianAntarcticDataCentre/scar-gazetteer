<template>
    <div>
        <div class="map-controls mb-2">
            <b-button-group size="sm">
                <b-button v-for="projection in projections" :variant="currentProjection == projection ? 'secondary' : 'outline-secondary'" :key="projection.name"
                    @click="setProjection(projection)">
                    {{ projection.name }}
                </b-button>
            </b-button-group>
        </div>
        <div ref="map" class="map-container"></div>
    </div>
</template>

<script>
import Feature from 'ol/Feature';
import Map from 'ol/Map';
import Point from 'ol/geom/Point';
import VectorLayer from 'ol/layer/Vector';
import VectorSource from 'ol/source/Vector';
import View from 'ol/View';
import { Style, Icon, Stroke } from 'ol/style';
import 'ol/ol.css';

import proj4 from "proj4";
import { register } from 'ol/proj/proj4.js';
import { join } from '../utils';
import TileLayer from 'ol/layer/Tile';

import WMTSCapabilities from 'ol/format/WMTSCapabilities.js';
import WMTS, {optionsFromCapabilities} from 'ol/source/WMTS.js';
import { Circle } from 'ol/geom';

const parser = new WMTSCapabilities();

// https://epsg.io/3031
proj4.defs("EPSG:3031", "+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +type=crs")

register(proj4)

const projections = [
    {
        name: 'Polar Stereographic',
        view: new View({
            center: [0, 0],
            zoom: 4,
            maxZoom: 22,
            extent: [-5000000, -5000000, 5000000, 5000000],
            //constrainOnlyCenter: false,
            projection: "EPSG:3031"
        }),
        basemap: loadWmtsLayer('https://tiles.arcgis.com/tiles/C8EMgrsFcRFL6LrL/arcgis/rest/services/Antarctic_Basemap/MapServer/WMTS/1.0.0/WMTSCapabilities.xml?cacheKey=a7cac5fc36cf8cca', 'Antarctic_Basemap')
    },
    {
        name: 'Mercator',
        view: new View({
            center: [0, -75],
            zoom: 0,
            maxZoom: 22,
        }),
        basemap: loadWmtsLayer('https://tiles.arcgis.com/tiles/C8EMgrsFcRFL6LrL/arcgis/rest/services/GEBCO_basemap_NCEI/MapServer/WMTS/1.0.0/WMTSCapabilities.xml?cacheKey=a1b48296ec17c253', 'GEBCO_basemap_NCEI')
    }
]

async function loadWmtsLayer(url, layer) {
    const response = await fetch(url)
    const text = await response.text()

    const result = parser.read(text);
    const options = optionsFromCapabilities(result, { layer })

    options.wrapX = true

    return new TileLayer({
        opacity: 1,
        source: new WMTS(options),
    })
}

function createAnnotationsLayer() {
    return new VectorLayer({
        source: new VectorSource(),
        style: new Style({
            image: new Icon({
                anchor: [0.5, 1],
                scale: 0.02,
                src: join(process.env.BASE_URL, `/static/marker.svg`)
            })
        })
    });
}

export default {
    props: {
        coordinates: {
            type: Object,
            required: true,
        },
    },
    data: () => ({
        map: null,
        annotationsLayer: createAnnotationsLayer(),
        currentProjection: projections[0]
    }),
    methods: {
        async setProjection(projection) {
            this.currentProjection = projection

            if (this.map.getView() == projection.view) return

            this.map.getLayers().clear()
            this.map.setView(projection.view)
            this.map.setLayers([await projection.basemap, this.annotationsLayer])

            this.updateAnnotations()
        },
        updateAnnotations() {
            const source = this.annotationsLayer.getSource()

            source.clear()

            if (this.coordinates && typeof this.coordinates?.longitude === 'number' && typeof this.coordinates?.latitude === 'number') {
                source.addFeature(new Feature({
                    // Convert from WGS84 to whatever view we're currently in
                    geometry: new Point(proj4("EPSG:4326", this.map.getView().getProjection().getCode(), [this.coordinates.longitude, this.coordinates.latitude]))
                }))
            } else {
                console.error("Invalid coordinates")
            }

            // Add a circle with the same colour as the background to hide the janky tile edge
            if (this.map.getView().getProjection().getCode() === 'EPSG:3031') {
                const polylineFeature = new Feature({
                    geometry: new Circle([0, 0], 4529797)
                })

                polylineFeature.setStyle(new Style({
                    stroke: new Stroke({
                        color: '#c1c1c1',
                        width: 6,
                    })
                }))

                source.addFeature(polylineFeature)
            }
        },
    },
    computed: {
        projections() {
            return projections
        },
    },
    watch: {
        coordinates() {
            this.updateAnnotations()
        },
    },
    async mounted() {
        this.map = new Map({
            target: this.$refs.map,
        })

        this.setProjection(this.currentProjection)
    },
    destroyed() {
        this.map.setTarget(null)
        this.map = null
    }
}
</script>

<style>
.map-container {
    border: 1px solid var(--bs-dark);
    height: 500px;
    background-color: #c1c1c1;
}
</style>