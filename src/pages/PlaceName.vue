<template>
    <div class="max-w-md" v-if="!place.$get.isPending && place.name_id">
        <header class="d-flex align-items-center flex-wrap">
            <h1 class="mb-0 mr-3">
                {{ place.place_name_gazetteer }}
            </h1>
            <b-button :to="`/place-names/${place.name_id}/edit`" v-if="$store.state.user.isAdmin" class="flex-grow-0" variant="outline-secondary"><BIconPencilSquare class="mr-1" />Edit</b-button>
        </header>
        <b-badge>Name ID: {{ place.name_id }}</b-badge> <b-badge>Place ID: {{ place.place_id }}</b-badge><br>
        <dl class="mt-2">
            <dt>Displayed as:</dt>
            <dd>{{ place.place_name_mapping || "Not recorded" }} <HelpHint content="How this place name appears on a map." /></dd>
            <dt>Feature type:</dt>
            <dd>
                <template v-if="place.feature_type">
                    <a :href="`https://data.aad.gov.au/feature-type/${place.feature_type.feature_type_code}`">{{ place.feature_type.feature_type_name }}</a> <HelpHint v-if="place.feature_type.definition" :content="`Geographic feature definition: ${place.feature_type.definition}`" />
                </template>
                <template v-else>
                    Not recorded
                </template>
            </dd>
            <template v-if="place.relic_flag">
                <dt>Is relic:</dt>
                <dd>Yes <HelpHint v-if="place.feature_type.definition" content="The feature this name belongs to no longer exists." /></dd>
            </template>
            <dt>Date named:</dt>
            <dd>{{ place.date_named || 'Not recorded' }}</dd>
        </dl>

        <audio v-if="place.pronunciation_audio_url" controls>
            <source :src="place.pronunciation_audio_url" type="audio/wav">
            Your browser does not support audio.
        </audio>

        <section>
            <h2>Origin</h2>
            <p>
                <template v-if="place.gazetteer">This name originates from <strong>{{ getNameForNumericIsoCountryCode(place.gazetteer.country_id) }}</strong>. It is part of the {{ gazetteerName }}, and the SCAR Composite Gazetteer of Antarctica.</template>
                <template v-else>The origin of this name is unknown as it is not associated with a gazetteer.</template>
            </p>

            <p>Other names for this place:</p>
            <ul>
                <li v-for="name of other_names" :key="name.name_id">
                    <router-link :to="'/place-names/' + name.name_id">{{ name.place_name_gazetteer }} ({{ name.gazetteer ? (name.gazetteer.gazetteer_name || getNameForNumericIsoCountryCode(name.gazetteer.country_id)) : 'Unknown' }})</router-link>
                </li>
            </ul>
        </section>

        <section>
            <div class="d-flex align-items-center mb-2">
                <h2 class="mr-2 mb-0">Narrative</h2>
                <HelpHint content="A description or a narrative about the place to which the record refers." />
            </div>
            <p v-if="place.narrative" v-html="sanitizeHtml(place.narrative)"></p>
            <p v-else>Not recorded.</p>
        </section>

        <section>
            <div class="d-flex align-items-center mb-2">
                <h2 class="mr-2 mb-0">Named for</h2>
                <HelpHint content="The reason the feature was given this name. Including details, for example, about the person, theme, or physical attributes." />
            </div>
            <p v-if="place.named_for" v-html="sanitizeHtml(place.named_for)"></p>
            <p v-else>Not recorded.</p>
        </section>

        <section>
            <h2>Location</h2>
            <dl>
                <dt>Decimal degrees:</dt>
                <dd>{{ place.geometry.coordinates[1] }}&deg;, {{ place.geometry.coordinates[0] }}&deg;</dd>
                <dt>Degrees, minutes, seconds:</dt>
                <dd>{{ toDMS(place.geometry.coordinates[1], isLatitude = true) }}, {{ toDMS(place.geometry.coordinates[0], isLatitude = false) }}</dd>
                <dt>Altitude:</dt>
                <dd>{{ place.altitude ? `${place.altitude}m` : "Not recorded" }}</dd>
                <dt>Location accuracy:</dt>
                <dd>{{ place.altitude_accuracy ? `${place.altitude_accuracy}m` : "Not recorded" }}</dd>
                <dt>Coordinate accuracy:</dt>
                <dd>{{ place.coordinate_accuracy ? `${place.coordinate_accuracy}m` : "Not recorded" }}</dd>
            </dl>
        </section>

        <section class="mb-3">
            <h2>Map</h2>
            <PlaceNameMap :coordinates="{ latitude: place.geometry.coordinates[1], longitude: place.geometry.coordinates[0] }" />
        </section>

        <section v-if="place.un_sdg && place.un_sdg > 0 && place.un_sdg <= Object.keys(un_sustainable_development_goal_descriptions).length" class="mb-3">
            <h2 class="mr-2 mb-0">UN Sustainable Development Goal</h2>
            <p>This place name is linked to a United Nations Sustainable Development Goal.</p>

            <b-card no-body class="overflow-hidden">
                <b-row no-gutters>
                    <b-col md="3">
                        <b-card-img :src="unsdgImage(place.un_sdg)"
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
        </section>

        <h2>Comments</h2>
        <p v-if="place.comments" v-html="sanitizeHtml(place.comments)"></p>
        <p v-else>No comments.</p>
    </div>
    <div v-else-if="!place.$get.isPending && !place.name_id">
        <NotFound />
    </div>
    <div v-else>
        <div class="d-flex justify-content-center">
            <b-spinner class="spinner"></b-spinner>
        </div>
    </div>
</template>

<script>
import { pg } from 'vue-postgrest'
import axios from 'axios'
import DOMPurify from 'dompurify'

import PlaceNameMap from '@/components/PlaceNameMap.vue'
import { getNameForNumericIsoCountryCode } from '@/utils'
import { join } from '../utils'
import NotFound from './NotFound.vue'
import { BIconPencilSquare } from 'bootstrap-vue'
import HelpHint from '@/components/HelpHint.vue'

export default {
    name: 'PlaceName',
    components: { PlaceNameMap, NotFound, BIconPencilSquare, HelpHint },
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
                    select: ['*', 'gazetteer:gazetteers(*), feature_type:feature_types(*)'],
                    and: {
                        'name_id.eq': this.$route.params.id
                    }
                },
                single: true
            }
        },
        gazetteerName() {
            return this.place.gazetteer.gazetteer_name || `${getNameForNumericIsoCountryCode(this.place.gazetteer.country_id)} gazetteer`
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
            const response = await axios.get(join(import.meta.env.BASE_URL, `/api/place_names?place_id=eq.${this.place.place_id}&name_id=neq.${this.place.name_id}&select=place_id,name_id,place_name_gazetteer,gazetteer:gazetteers(gazetteer_name,country_id)`))
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
        unsdgImage(unsdg) {
            return join(import.meta.env.BASE_URL, `/static/un_sdg/un_sdg_${unsdg}.png`)
        },
        getNameForNumericIsoCountryCode,
        join
    },
}
</script>

<style scoped>
dl {
    display: grid;
    grid-template-columns: auto;
    column-gap: .5em;
}

@media (min-width: 576px) {
    dl {
        grid-template-columns: max-content auto;
    }
}

dd {
    margin-bottom: .3em;
}

dd:last-child {
    margin-bottom: 0;
}
</style>