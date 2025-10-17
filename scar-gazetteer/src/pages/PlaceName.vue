<template>
    <b-container class="place" v-if="!place.$get.isPending && place.id">
        <h1>
            {{ place.place_name_mapping }}
            <b-button :to="`/place-name/${place.name_id}/edit`" v-if="$store.state.user.isAdmin"><b-icon-pencil-square/> Edit</b-button>
        </h1>
        <b-badge>Name ID: {{ place.name_id }}</b-badge> <b-badge>Place ID: {{ place.place_id }}</b-badge><br>
        <p v-if="place.feature_types">
            Feature type: 
            <a :href="`https://data.aad.gov.au/feature-type/${place.feature_types.feature_type_code}`">{{ place.feature_types.feature_type_name }}</a>
            <span v-if="place.feature_types.definition" v-b-tooltip.hover :title="place.feature_types.definition">
                <b-icon-info-circle />
            </span>
        </p>

        <audio v-if="place.pronunciation_audio_url" controls>
            <source :src="place.pronunciation_audio_url" type="audio/wav">
            Your browser does not support audio.
        </audio>

        <h3>Origin</h3>
        <p v-if="place.gazetteers">
            This name originates from <strong>{{ getNameForNumericIsoCountryCode(place.gazetteers.country_id) }}</strong>.
            It is part of the {{ gazetteerName }}, and the SCAR Composite Gazetteer of Antarctica.
        </p>

        <div v-if="other_names.length">
            <p>Other names for this place:</p>
            <ul>
                <li v-for="name of other_names" :key="name.name_id">
                    <router-link :to="'/place-name/' + name.name_id"> {{ name.place_name_mapping }}({{ name.gazetteer }})</router-link>
                </li>
            </ul>
        </div>

        <div v-if="place.narrative">
            <h3>Narrative</h3>
            <p v-html="sanitizeHtml(place.narrative)"></p>
        </div>

        <div v-if="place.narrative_translation">
            <h3>Narrative translation</h3>
            <p v-html="sanitizeHtml(place.narrative_translation)"></p>
            <div v-if="place.machine_translation">
                <b-alert variant="info" show><b-icon-info-circle-fill /> Note: This text has been machine-translated and may not be accurate.</b-alert>
            </div>
        </div>

        <div v-if="place.named_for">
            <h3>Named for</h3>
            <p v-html="sanitizeHtml(place.named_for)"></p>
        </div>

        <template v-if="place.un_sdg && place.un_sdg > 0 && place.un_sdg <= Object.keys(un_sustainable_development_goal_descriptions).length">
            <h3>UN Sustainable Development Goal</h3>
            <p>This place name is linked to a United Nations Sustainable Development goal.</p>

            <b-card no-body class="overflow-hidden">
                <b-row no-gutters>
                    <b-col md="3">
                        <b-card-img :src="join(process.env.BASE_URL, `/static/un_sdg/un_sdg_${place.un_sdg}.png`)"
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
        </template>

        <h3>Location</h3>
        <ul>
            <li>Latitude: {{ place.geometry.coordinates[1] }}° ({{ toDMS(place.geometry.coordinates[1], isLatitude = true) }})</li>
            <li>Longitude: {{ place.geometry.coordinates[0] }}° ({{ toDMS(place.geometry.coordinates[0], isLatitude = false) }})</li>
            <li>Altitude: {{ place.altitude || "Not recorded" }}</li>
        </ul>

        <h3>Map</h3>
        <PlaceNameMap :coordinates="{ latitude: place.geometry.coordinates[1], longitude: place.geometry.coordinates[0] }" />

        <template v-if="place.comments != null">
            <h3>Comments</h3>
            <p>{{ place.comments }}</p>
        </template>
    </b-container>
    <b-container v-else-if="!place.$get.isPending && !place.id">
        <NotFound />
    </b-container>
    <b-container v-else>
        <div class="spinner-div d-flex justify-content-center">
            <b-spinner class="spinner"></b-spinner>
        </div>
    </b-container>
</template>

<script>
import { pg } from 'vue-postgrest'
import axios from 'axios'
import DOMPurify from 'dompurify'

import PlaceNameMap from '@/components/PlaceNameMap.vue'
import { getNameForNumericIsoCountryCode } from '@/utils'
import { join } from '../utils'
import NotFound from './NotFound.vue'

export default {
    name: 'PlaceName',
    components: { PlaceNameMap, NotFound },
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
                    "latitude": this.place.geometry?.coordinates[1],
                    "longitude": this.place.geometry?.coordinates[0],
                },
                "name": this.place.place_name_mapping,
                // Sanitize HTML to convert any formatting to plain text
                "description": DOMPurify.sanitize(this.place.narrative || "", { USE_PROFILES: {}, KEEP_CONTENT: true }),
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
        gazetteerName() {
            return this.place.gazetteers.gazetteer_name || `${getNameForNumericIsoCountryCode(this.place.gazetteers.country_id)} gazetteer`
        },
        transformedNarrativeParts() {
            if (!this.place.narrative) return []
            return this.transformLinks(this.place.narrative)
        }
    },
    watch: {
        'pg.name_id': function () {
            this.getOtherNames()
        }
    },
    methods: {
        async getOtherNames() {
            this.other_names = []
            const response = await axios.get(join(process.env.BASE_URL, `/api/place_names?place_id=eq.${this.place.place_id}&name_id=neq.${this.place.name_id}`))
            this.other_names = response.data
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
        sanitizeHtml(html) {
            return DOMPurify.sanitize(html, { ALLOWED_TAGS: ['b', 'strong', 'i', 'em', 'a', 'br', 'mark', 'q', 'sub', 'sup', 'u'], KEEP_CONTENT: true })
        },
        getNameForNumericIsoCountryCode,
        join
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
</style>
