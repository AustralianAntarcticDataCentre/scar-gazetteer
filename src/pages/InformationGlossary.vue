<template>
    <div>
        <h1>Glossary</h1>
        <div class="">
            <Loading v-if="pg.$get.isPending" />
            <template v-else>
                <b-form-group label="Search glossary" label-for="filter-input">
                    <b-form-input id="filter-input" v-model="filter" type="search" placeholder="Query"></b-form-input>
                </b-form-group>

                <b-pagination v-model="currentPage" :total-rows="filteredRows" :per-page="perPage"
                    aria-controls="glossary-table" class="mb-3"></b-pagination>

                <b-table id="glossary-table" :items="filteredGlossary" :fields="fields" :per-page="perPage"
                    :current-page="currentPage" striped hover label-sort-asc="" label-sort-desc="" label-sort-clear="" responsive />

                <b-pagination v-model="currentPage" :total-rows="filteredRows" :per-page="perPage"
                    aria-controls="glossary-table"></b-pagination>
            </template>
        </div>
    </div>
</template>

<script>
import { pg } from 'vue-postgrest'
import Loading from '@/components/Loading.vue';

export default {
    name: 'InformationGlossary',
    components: { Loading },
    data: function () {
        return {
            perPage: 50,
            currentPage: 1,
            filter: '',
            fields: [
                { key: 'english_term', sortable: true },
                { key: 'national_term', sortable: true },
                { key: 'language', sortable: true },
                { key: 'feature_type.name', sortable: true, label: 'Feature Type' },
            ]
        }
    },
    mixins: [pg],
    computed: {
        rows() {
            return this.pg.length
        },
        glossary() {
            return this.pg
        },
        filteredGlossary() {
            if (!this.filter) {
                return this.glossary
            }

            const properties = ['english_term', 'national_term', 'language', 'feature_type.name']

            return this.glossary.filter(entry => {
                return properties.some(prop => entry[prop] && entry[prop].toLowerCase().includes(this.filter.toLowerCase()))
            })
        },
        filteredRows() {
            return this.filteredGlossary.length
        },
        pgConfig() {
            return {
                route: 'glossary',
                query: {
                    select: ['*', 'feature_type:feature_types(name:feature_type_name))']
                }
            }
        }
    },
    watch: {
        '$route.params.id': function () {
            this.pg.$get
        },
        filter() {
            this.currentPage = 1 // reset to first upon page when filtering
        }
    },
    metaInfo: {
        title: 'Glossary',
    },
}
</script>
