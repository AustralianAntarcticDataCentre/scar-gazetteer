<template>
    <b-container class="place">
        <h1>{{ place.place_name_mapping }} <b-button :to="`/place-name/${place.name_id}/edit`"
                v-if="$store.state.user.isAdmin">Edit</b-button></h1>
        <b-badge>Name ID: {{ place.name_id }}</b-badge> <b-badge>Place ID: {{ place.place_id }}</b-badge><br>
        <p v-if="place.feature_types">Feature Type: <a
                :href="`https://data.aad.gov.au/feature-type/${place.feature_types.feature_type_code}`">{{
                    place.feature_types.feature_type_name }}</a>
            <b-icon-info-circle v-b-tooltip.hover :title="place.feature_types.definition" />
        </p>

        <h3>Origin</h3>
        <p v-if="place.gazetteers">This name originates from <strong>{{ place.gazetteers.country }}</strong>. It is part
            of the {{ gazetteerName }} and the SCAR Composite Gazetteer of Antarctica.</p>

        <div v-if="other_names.length > 0">
            <p>Names that other countries have for this feature: </p>
            <ul>
                <li v-for="name of other_names" :key="name.name_id">
                    <router-link :to="'/place-name/' + name.name_id"> {{ name.place_name_mapping }}
                        ({{ name.gazetteer }})</router-link>
                </li>
            </ul>
        </div>

        <div v-if="place.narrative">
            <h3>Narrative</h3>
            <p>
                <component v-for="(part, index) in transformedNarrativeParts" :key="index" :is="part.component"
                    v-bind="part.props">
                    {{ part.text }}
                </component>
            </p>
        </div>

        <div v-if="place.narrative_translation">
            <h3>Narrative Translation</h3>
            <p>{{ place.narrative_translation }}</p>
            <div v-if="place.machine_translation">
                <b-alert variant="info" show><b-icon-info-circle-fill /> Note: This text has been machine-translated and may not be accurate.</b-alert>
            </div>
        </div>

        <div v-if="place.named_for">
            <h3>Named For</h3>
            <p>{{ place.named_for }}</p>
        </div>

        <div v-if="themes.length > 0">
            <h3>Themes</h3>
            <p>This place is included in these themes:</p>
            <span v-for="(theme, index) in themes" :key="theme">
                <router-link :to="'/information/themes#' + theme.name">{{ theme.name }}</router-link>
                <span v-if="index + 1 < themes.length">, </span>
            </span>
        </div>

        <div
            v-if="place.un_sdg && place.un_sdg > 0 && place.un_sdg <= Object.keys(un_sustainable_development_goal_descriptions).length">
            <h3>UN Sustainable Development Goal</h3>
            <p>This place name is linked to a United Nations Sustainable Development goal.</p>

            <b-card no-body class="overflow-hidden">
                <b-row no-gutters>
                    <b-col md="3">
                        <b-card-img :src="`/static/un_sdg/un_sdg_${place.un_sdg}.png`"
                            :alt="`UN Sustainable Development Goal Number ${place.un_sdg}`" class="h-100"></b-card-img>
                    </b-col>
                    <b-col md="8">
                        <b-card-body>
                            <b-card-text>{{ un_sustainable_development_goal_descriptions[place.un_sdg] }}</b-card-text>
                            <small class="text-muted">Learn more at <a
                                    :href="`https://sdgs.un.org/goals/goal${place.un_sdg}`">United Nations Sustainable
                                    Development Goals | Goal {{ place.un_sdg }}</a>.</small>
                        </b-card-body>
                    </b-col>
                </b-row>
            </b-card>

        </div>

        <h3>Location</h3>
        <ul>
            <li>Latitude: {{ place.latitude }}° ({{ toDMS(place.latitude, isLatitude = true) }})</li>
            <li>Longitude: {{ place.longitude }}° ({{ toDMS(place.longitude, isLatitude = false) }})</li>
            <li>Altitude: {{ place.altitude || "Not Recorded" }}</li>
        </ul>

        <h3>Map</h3>
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
        <div id="map-container"></div>

        <h3>Source</h3>
        <ul>
            <li>Location Method: {{ place.location_method_id || "Not Recorded" }}</li>
            <li>Source Name: {{ place.source_name || "Not Recorded" }}</li>
            <li>Source Publisher: {{ place.source_publisher || "Not Recorded" }}</li>
            <li>Source Scale: {{ place.source_scale || "Not Recorded" }}</li>
            <li>Source Identifier: {{ place.source_identifier || "Not Recorded" }}</li>
        </ul>

        <div v-if="place.comments != null">
            <h3>Comments</h3>
            <p>{{ place.comments }}</p>
        </div>
    </b-container>
</template>

<script>
import { pg } from 'vue-postgrest'
import axios from 'axios'

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

const markerSource = new VectorSource();

const markerLayer = new VectorLayer({
    source: markerSource,
    style: new Style({
        image: new Icon({
            anchor: [0.5, 1],
            scale: 0.02,
            src: '/static/marker.svg'
        })
    })
});

export default {
    name: 'PlaceName',
    metaInfo: function () {
        return {
            script: [{
                type: 'application/ld+json',
                json: this.jsonld
            }]
        }
    },
    data: function () {
        return {
            other_names: [],
            themes: [],
            un_sustainable_development_goal_descriptions: {
                1: "No Poverty – End poverty in all its forms everywhere.",
                2: "Zero Hunger – End hunger, achieve food security and improved nutrition, and promote sustainable agriculture.",
                3: "Good Health and Well-being – Ensure healthy lives and promote well-being for all at all ages.",
                4: "Quality Education – Ensure inclusive and equitable quality education and promote lifelong learning opportunities for all.",
                5: "Gender Equality – Achieve gender equality and empower all women and girls.",
                6: "Clean Water and Sanitation – Ensure availability and sustainable management of water and sanitation for all.",
                7: "Affordable and Clean Energy – Ensure access to affordable, reliable, sustainable, and modern energy for all.",
                8: "Decent Work and Economic Growth – Promote sustained, inclusive, and sustainable economic growth, full and productive employment, and decent work for all.",
                9: "Industry, Innovation, and Infrastructure – Build resilient infrastructure, promote inclusive and sustainable industrialization, and foster innovation.",
                10: "Reduced Inequality – Reduce inequality within and among countries.",
                11: "Sustainable Cities and Communities – Make cities and human settlements inclusive, safe, resilient, and sustainable.",
                12: "Responsible Consumption and Production – Ensure sustainable consumption and production patterns.",
                13: "Climate Action – Take urgent action to combat climate change and its impacts.",
                14: "Life Below Water – Conserve and sustainably use the oceans, seas, and marine resources for sustainable development.",
                15: "Life on Land – Protect, restore, and promote the sustainable use of terrestrial ecosystems, manage forests sustainably, combat desertification, halt and reverse land degradation, and halt biodiversity loss.",
                16: "Peace, Justice, and Strong Institutions – Promote peaceful and inclusive societies for sustainable development, provide access to justice for all, and build effective, accountable, and inclusive institutions at all levels.",
                17: "Partnerships for the Goals – Strengthen the means of implementation and revitalize the global partnership for sustainable development."
            },
            map: null,
            mapProjection: "EPSG:3031"
        }
    },
    mixins: [pg],
    computed: {
        jsonld() {
            return {
                '@context': 'http://schema.org',
                "@type": "Place",
                "geo": {
                    "@type": "GeoCoordinates",
                    "latitude": this.place?.latitude,
                    "longitude": this.place?.longitude
                },
                "name": this.place?.place_name_mapping,
                "description": this.place?.narrative,
                "url": `${window.location}`
            }
        },
        place() {
            return this.pg
        },
        pgConfig() {
            return {
                route: 'place_names',
                query: {
                    select: ['*', 'gazetteers(*), feature_types(*)'],
                    and: {
                        'name_id.eq': this.$route.params.id
                    }
                },
                single: true
            }
        },
        markerLatLng() {
            return [this.place.latitude || 0, this.place.longitude || 0]
        },
        gazetteerName() {
            return this.place.gazetteers.gazetteer_name ?? `${this.place.gazetteers.country} Gazetteer`
        },
        transformedNarrativeParts() {
            if (!this.place.narrative) return []
            return this.transformLinks(this.place.narrative)
        }
    },
    watch: {
        '$route.params.id': async function () {
            await this.pg.$get()
            await this.getOtherNames()
            await this.getThemes()
        },
        'pg': function () {
            this.getOtherNames()
            this.getThemes()
            this.updateMarker()
        }
    },
    methods: {
        getOtherNames: async function () {
            const response = await axios.get(`/api/place_names?place_id=eq.${this.place.place_id}&name_id=neq.${this.place.name_id}`)
            this.other_names = response.data
        },
        getThemes: async function () {
            const response = await axios.get(`/api/themes?place_names=cs.{${this.place.place_name_mapping}}`)
            this.themes = response.data
        },

        toDMS(decimal_degrees, isLatitude) {
            const degrees = Math.floor(Math.abs(decimal_degrees));
            const minutesFloat = (Math.abs(decimal_degrees) - degrees) * 60;
            const minutes = Math.floor(minutesFloat);
            const seconds = ((minutesFloat - minutes) * 60).toFixed(2);

            let directionLetter = "";
            if (isLatitude) {
                directionLetter = decimal_degrees >= 0 ? "N" : "S";
            } else {
                directionLetter = decimal_degrees >= 0 ? "E" : "W";
            }

            return `${degrees}° ${minutes}' ${seconds}" ${directionLetter}`;
        },

        // transform [L]link to other place[/L]
        transformLinks(narrative_text) {
            const parts = []
            const markupLinkRegex = /\[L\](.*?)\[\/L\]/g
            let lastIndex = 0
            let match

            while ((match = markupLinkRegex.exec(narrative_text)) !== null) {
                if (match.index > lastIndex) {
                    parts.push({
                        component: 'span',
                        text: narrative_text.substring(lastIndex, match.index),
                        props: {}
                    })
                }

                const place_name = match[1]
                parts.push({
                    component: 'router-link',
                    text: place_name,
                    props: {
                        to: {
                            path: '/search/results',
                            query: { search_text: place_name }
                        }
                    }
                })

                lastIndex = match.index + match[0].length
            }

            if (lastIndex < narrative_text.length) {
                parts.push({
                    component: 'span',
                    text: narrative_text.substring(lastIndex),
                    props: {}
                })
            }

            if (parts.length === 0) {
                parts.push({
                    component: 'span',
                    text: narrative_text,
                    props: {}
                })
            }

            return parts
        },
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

                layers.push(markerLayer)
                this.updateMarker()
            }
        },
        updateMarker() {
            if (this.place && this.place.latitude != null && this.place.longitude != null) {
                if (markerSource) {
                    markerSource.clear();

                    let markerFeature = null;

                    if (this.mapProjection === "EPSG:3031") {
                        markerFeature = new Feature({
                            // 4326 is standard, unprojected coordinate system
                            // 3031 is Antarctic Polar Stereographic
                            geometry: new Point(proj4("EPSG:4326", "EPSG:3031", [this.place.longitude, this.place.latitude]))
                        });
                    } else {
                        markerFeature = new Feature({
                            // 3857 is Web Mercator
                            geometry: new Point(proj4("EPSG:4326", "EPSG:3857", [this.place.longitude, this.place.latitude]))
                        });
                    }

                    markerSource.addFeature(markerFeature);
                }
            }
        },
    },
    mounted() {
        this.map = new Map({
            target: 'map-container',
            layers: [
                antarcticaLayer,
                markerLayer,
            ],
            view: polarStereographicView
        });
    },
}
</script>

<style>
.badge {
    color: #fff;
    background-color: #999;
    text-shadow: 0 -1px 0 rgb(0 0 0 / 25%);
}

.place {
    max-width: 60em;
}

#map-container {
  border: 1px solid var(--bs-dark);
  height: 500px;
  background-color: #8bcfef;
}
</style>
