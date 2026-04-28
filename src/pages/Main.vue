<template>
    <div class="main-content">
        <h1>Composite Gazetteer of Antarctica</h1>

        <BCard bg-variant="light" tag="form" class="mb-3" @submit.prevent="search">
            <label for="homepage-search" class="sr-only">Search place names</label>
            <BInputGroup>
                <BFormInput id="homepage-search" v-model="form.search_text" placeholder="Search place names..."/>
                <template #append>
                    <BButton type="submit"><BIconSearch /><span class="sr-only">Search</span></BButton>
                </template>
            </BInputGroup>
            <div class="small mt-2" style="margin-bottom: -.4em;">
                <BLink to="/search">Advanced search</BLink><br>
                <BLink to="/search/results">View all names</BLink>
            </div>
        </BCard>

        <p>The <a href="https://scar.org" target="_blank">SCAR</a> Composite Gazetteer of Antarctica (CGA) offers a composite collection of all Antarctic place names contributed to by <b-link to="/information/statistics">{{ gazetteer_count.toLocaleString() }} countries</b-link>. It includes the names of features south of 60°S, both terrestrial, near shore and under-ice.</p>

        <p>It commenced in 1992 and continues to be updated, consisting of <b-link :to="'/search/results'">{{ name_count.toLocaleString() }} names</b-link> that correspond to {{ feature_count.toLocaleString() }} features.</p>

        <p>The CGA provides support for the scientific community as well as for operational activities and emergency management. The CGA offers practical identification of places, acknowledging discovery, exploration, physical description, and commemoration. Good practice naming guidelines, <a href="https://scar.org/~documents/route%3A/download/5729" target="_blank">International Principles and Procedures for Antarctic Place Names (SCAR Report 41)</a> are encouraged by SCAR to ensure standardised, consistent and accurate place naming in Antarctica.</p>

        <p>Since 2008, Italy and Australia jointly have managed the CGA, the former taking care of the editing, the latter maintaining the database and website. The SCAR <a href="https://scar.org/science/standing/scagi">Standing Committee on Antarctic Geographic Information (SCAGI)</a> coordinates the project.</p>

        <p>For queries about the CGA email <a href="mailto:scar.cga@unisi.it">scar.cga@unisi.it</a>.</p>

        <ul class="unstyled">
            <li><BIconBarChart style="text-align: center" /> <b-link to="/information/statistics"> View SCAR Gazetteer
                    statistics</b-link></li>
            <li><BIconCloudArrowDown style="text-align: center" /> <b-link to="/information/download"> Download SCAR Gazetteer</b-link>
            </li>
            <li><BIconFileEarmarkText style="text-align: center" /> <b-link to="/information/batch-instructions">
                    Instructions for batch edits</b-link></li>
        </ul>
    </div>
</template>

<script>
import qs from "qs";
import axios from 'axios'
import { join } from '../utils';
import { BIconBarChart, BIconCloudArrowDown, BIconFileEarmarkText, BIconSearch } from 'bootstrap-vue';

export default {
    name: "Main",
    components: { BIconBarChart, BIconCloudArrowDown, BIconFileEarmarkText, BIconSearch },
    data: function () {
        return {
            feature_count: 0,
            name_count: 0,
            gazetteer_count: 0,
            form: {
                search_text: "",
            },
        }
    },
    computed: {
        years: function () {
            return new Date().getFullYear() - 1992
        }
    },
    methods: {
        search() {
            this.$router.push(`/search/results?${qs.stringify(this.form)}`);
        }
    },
    metaInfo: function () {
        return {
            script: [{
                type: 'application/ld+json',
                json: {
                    "@context": "https://schema.org",
                    "@type": "WebPage",
                    "name": 'SCAR Composite Gazetteer of Antarctica',
                    "sourceOrganization": {
                        "@type": "Organization",
                        "name": "PROGRAMMA NAZIONALE DI RICERCHE IN ANTARTIDE",
                        "url": "https://www.pnra.aq/",
                        "logo": "https://www.pnra.aq/themes/basic/logo.png"
                    },
                    "publisher": {
                        "@type": "Organization",
                        "name": "Scientific Committee on Antarctic Research (SCAR)",
                        "url": "https://scar.org",
                        "logo": "https://scar.org/templates/it_headlines/custom/images/SCAR_logo_2018_white_background.png"
                    },
                    "spatialCoverage": {
                        "@type": "Place",
                        "geo": {
                            "@type": "GeoShape",
                            "box": "-90 180 -60 -180"
                        }
                    },
                    "potentialAction": {
                        "@type": "SearchAction",
                        "target": "https://placenames.aq/search/results?search_text={search_term_string}",
                        "query-input": "required name=search_term_string"
                    }
                }
            }]
        }
    },
    mounted: async function () {
        const response = await axios.get(join(import.meta.env.BASE_URL, `/api/gaz_count`))
        this.name_count = response.data[0].name_count
        this.feature_count = response.data[0].place_count
        this.gazetteer_count = response.data[0].gazetteer_count
    }
}
</script>


<style scoped>
.unstyled {
    list-style: none;
    /* Remove list bullets */
    padding: 0;
    margin: 0;
}

.main-content {
    max-width: 50rem;
}
</style>
