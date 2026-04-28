<template>
    <div class="max-w-md">
        <h1>Search results</h1>
        <Loading v-if="loading" />
        <template v-else>
            <p>
                {{ count.toLocaleString() }} total results {{ $route.query.search_text ? `for "${$route.query.search_text}"` : '' }}
            </p>
            <div class="d-flex justify-content-between flex-wrap mb-3">
                <b-pagination-nav :link-gen="generatePageLink" :number-of-pages="total_pages" use-router first-number last-number class="mr-3"></b-pagination-nav>
                <b-button @click="download" variant="outline-secondary"><BIconDownload /> Download</b-button>
            </div>
            <b-table v-if="!loading" :items="results" :fields="fields" responsive>
                <template #cell(place_name_gazetteer)="p">
                    <div>
                        <b-link :to="`/place-names/${p.item.name_id}`">{{ p.item.place_name_gazetteer }}
                            ({{ p.item.gazetteer_code || 'Unknown' }})</b-link><br />
                        <b-badge>Name ID: {{ p.item.name_id }}</b-badge> <b-badge>Place ID: {{ p.item.place_id }}</b-badge>
                    </div>
                </template>
                <template #cell(latitude)="lat">
                    <div>
                        {{ lat.item.latitude }}°
                    </div>
                </template>
                <template #cell(longitude)="lon">
                    <div>
                        {{ lon.item.longitude }}°
                    </div>
                </template>
                <template #cell(feature_types)="f">
                    <div v-if="f.item.feature_type_name">
                        <a
                            :href="`https://data.aad.gov.au/feature-type/${f.item.feature_type_code}`">{{ f.item.feature_type_name }}</a>
                    </div>
                </template>
            </b-table>
            <Loading v-else class="mb-3" />
            <b-pagination-nav :link-gen="generatePageLink" :number-of-pages="total_pages" use-router first-number last-number></b-pagination-nav>
        </template>
    </div>
</template>

<script>
import qs from 'qs'
import axios from 'axios'
import { join } from '../utils';
import { BIconDownload } from 'bootstrap-vue';
import Loading from '../components/Loading.vue';

export default {
    name: 'SearchResults',
    components: { BIconDownload, Loading },
    data: function () {
        return {
            loading: true,
            fields: [
                { key: 'place_name_gazetteer', label: "Place name", sortable: false },
                { key: 'latitude', sortable: false },
                { key: 'longitude', sortable: false },
                { key: 'feature_types', label: "Feature type", sortable: false }
            ],
            page_size: 25,
            results: [],
            count: 0
        }
    },
    computed: {
        page() {
            return Math.max(this.$route.query.page ?? 1, 1)
        },
        total_pages() {
            return Math.max(Math.ceil(this.count / this.page_size), 1)
        }
    },
    mounted: function () {
        this.search()
    },
    watch: {
        '$route': function () {
            this.search()
        }
    },
    methods: {
        parseFilter: function () {
            let filter = {}

            if (this.$route.query.search_text) {
                filter['search_text'] = `${this.$route.query.search_text}`
            } else {
                filter['search_text'] = ''
            }

            if (this.$route.query.gazetteer) {
                filter['gazetteer_code'] = `eq.${this.$route.query.gazetteer}`
            }

            if (this.$route.query.feature_type) {
                filter['feature_type_code'] = `eq.${this.$route.query.feature_type}`
            }

            if (this.$route.query.relics === 'exclude') {
                filter['is_relic'] = `is.false`
            }

            if (this.$route.query.relics === 'only') {
                filter['is_relic'] = `is.true`
            }

            if (this.$route.query.date_after && this.$route.query.date_before) {
                filter['date_named'] = [`gte.${this.$route.query.date_after}`, `lte.${this.$route.query.date_before}`]
            } else if (this.$route.query.date_after) {
                filter['date_named'] = `gte.${this.$route.query.date_after}`
            } else if (this.$route.query.date_before) {
                filter['date_named'] = `lte.${this.$route.query.date_before}`
            }

            filter['order'] = 'place_name_gazetteer.asc'

            return filter
        },
        search: async function () {
            this.loading = true
            let filter = this.parseFilter()

            filter['limit'] = this.page_size
            filter['offset'] = (this.page - 1) * this.page_size

            try {
                const response = await axios.get(join(import.meta.env.BASE_URL, `/api/rpc/search?select=name_id,place_id,place_name_gazetteer,latitude,longitude,feature_type_code,feature_type_name,gazetteer_code,is_relic,date_named&${qs.stringify(filter, { arrayFormat: "repeat" })}`), { headers: { 'Prefer': 'count=exact' } })
                this.results = response.data
                this.count = Number(response.headers['content-range'].split('/')[1])
            } catch (error) {
                console.error(error)
                alert(`Unable to perform search: ${error}`)
            } finally {
                this.loading = false
            }
        },
        generatePageLink(pageNumber) {
            return {
                query: { ...this.$route.query, page: pageNumber },
            }
        },
        download: function () {
            let filter = this.parseFilter()

            axios({
                url: join(import.meta.env.BASE_URL, `/api/rpc/search?${qs.stringify(filter, { arrayFormat: "repeat" })}`),
                method: 'GET',
                headers: { 'Accept': 'text/csv' }
            }).then((response) => {
                const url = window.URL.createObjectURL(new Blob([response.data]));
                const link = document.createElement('a');
                link.href = url;
                link.setAttribute('download', 'scar-gazetteer.csv');
                document.body.appendChild(link);
                link.click();
            });
        }
    },
}
</script>

<style scoped>
.badge {
    color: #fff;
    background-color: #999;
    text-shadow: 0 -1px 0 rgb(0 0 0 / 25%);
}

.control {
    display: flex;
    flex-direction: row;
    align-items: stretch;
    gap: 1.5em;
}

.page-control {
    display: flex;
    gap: 1em;
    flex-grow: 1;
}
</style>
