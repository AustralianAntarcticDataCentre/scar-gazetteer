<template>
    <b-container class="search">
        <h1>Search results</h1>
        <p>
            Page: {{ page.toLocaleString() }} of {{ total_pages.toLocaleString() }}<br>
            Total results: {{ count.toLocaleString() }}
        </p>
        <div class="control">
            <div class="page-control" v-if="total_pages > 1">
                <b-button @click="previous" :disabled="page == 1">Previous</b-button>
                <b-button @click="next" :disabled="page >= total_pages">Next</b-button>
            </div>
            <div class="download-control">
                <b-button @click="download" variant="outline-primary"><b-icon-download /> Download</b-button>
            </div>
        </div>
        <b-table v-if="!loading" :items="results" :fields="fields">
            <template #cell(place_name_mapping)="p">
                <div>
                    <b-link :to="`/place-name/${p.item.name_id}`">{{ p.item.place_name_mapping }}
                        ({{ p.item.gazetteer_code }})</b-link><br />
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
        <b-container v-else>
            <div class="spinner-div d-flex justify-content-center">
                <b-spinner class="spinner"></b-spinner>
            </div>
        </b-container>
        <div class="control" v-if="total_pages > 1">
            <div class="page-control">
                <b-button @click="previous" :disabled="page == 1">Previous</b-button>
                <b-button @click="next" :disabled="page >= total_pages">Next</b-button>
            </div>
        </div>
    </b-container>
</template>

<script>
import qs from 'qs'
import axios from 'axios'

export default {
    name: 'SearchResults',
    data: function () {
        return {
            loading: false,
            fields: [
                { key: 'place_name_mapping', label: "Place name", sortable: false },
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
            return Math.ceil(this.count / this.page_size)
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

            if (this.$route.query.relics == 1) {
                filter['relic_flag'] = `is.false`
            }

            if (this.$route.query.relics == 2) {
                filter['relic_flag'] = `is.true`
            }

            if (this.$route.query.date_after && this.$route.query.date_before) {
                filter['date_named'] = [`gte.${this.$route.query.date_after}`, `lte.${this.$route.query.date_before}`]
            } else if (this.$route.query.date_after) {
                filter['date_named'] = `gte.${this.$route.query.date_after}`
            } else if (this.$route.query.date_before) {
                filter['date_named'] = `lte.${this.$route.query.date_before}`
            }

            filter['order'] = 'place_name_mapping.asc'

            return filter
        },
        search: async function () {
            this.loading = true
            let filter = this.parseFilter()

            filter['limit'] = this.page_size
            filter['offset'] = (this.page - 1) * this.page_size

            try {
                const response = await axios.get(`/api/rpc/search?select=name_id,place_id,place_name_mapping,latitude,longitude,feature_type_code,feature_type_name,gazetteer_code&${qs.stringify(filter, { arrayFormat: "repeat" })}`, { headers: { 'Prefer': 'count=exact' } })
                this.results = response.data
                this.count = Number(response.headers['content-range'].split('/')[1])
            } catch (error) {
                console.error(error)
                alert(`Unable to perform search: ${error}`)
            } finally {
                this.loading = false
            }
        },
        next: function () {
            if (this.page >= this.total_pages) {
                return
            }

            const query = Object.assign({}, this.$route.query);
            query.page = parseInt(this.page) + 1;
            this.$router.push({ query });
        },
        previous: function () {
            if (this.page == 1) {
                return
            }

            const query = Object.assign({}, this.$route.query);
            query.page = parseInt(this.page) - 1;
            this.$router.push({ query });
        },
        download: function () {
            let filter = this.parseFilter()

            axios({
                url: `/api/rpc/search?${qs.stringify(filter, { arrayFormat: "repeat" })}`,
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

.search {
    max-width: 50em;
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
