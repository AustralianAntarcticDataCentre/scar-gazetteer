<script>
import { BIconChevronDoubleDown } from 'bootstrap-vue';

export default {
    components: { BIconChevronDoubleDown },
    data: () => ({
        showNavigation: true,
        isMinWidthLg: true,
        mediaQueryList: null,
    }),
    methods: {
        onMediaQueryListChange(event) {
            this.isMinWidthLg = event.matches
        }
    },
    watch: {
        isMinWidthLg() {
            this.showNavigation = this.isMinWidthLg
        },
        '$route'() {
            this.showNavigation = this.isMinWidthLg
        }
    },
    created() {
        this.mediaQueryList = window.matchMedia("(min-width: 992px)"); // Bootstrap lg breakpoint
        this.isMinWidthLg = this.mediaQueryList.matches
        this.mediaQueryList.addEventListener("change", this.onMediaQueryListChange)
    },
    destroyed() {
        this.mediaQueryList.removeEventListener("change", this.onMediaQueryListChange)
        this.mediaQueryList = null
    }
}
</script>

<template>
    <div>
        <b-row>
            <b-col cols="12" lg="3">
                <b-card tag="nav" no-body class="overflow-hidden mb-3 mb-lg-0">
                    <b-card-header class="pl-3 pr-2 py-2 d-lg-none d-flex justify-content-between align-items-center">
                        <h6 class="mb-0">Information</h6>
                        <b-button size="sm" v-b-toggle.information-nav variant="outline-secondary">
                            <BIconChevronDoubleDown />
                            <span class="sr-only">Show menu</span>
                        </b-button>
                    </b-card-header>
                    <b-collapse id="information-nav" v-model="showNavigation" role="tabpanel">
                        <b-list-group flush>
                            <b-list-group-item to="/information">General information</b-list-group-item>
                            <b-list-group-item to="/information/terminology">Terminology</b-list-group-item>
                            <b-list-group-item to="/information/statistics">Statistics</b-list-group-item>
                            <b-list-group-item to="/information/glossary">Glossary</b-list-group-item>
                            <b-list-group-item to="/information/naming-authorities">Naming authorities</b-list-group-item>
                            <b-list-group-item to="/information/history">History</b-list-group-item>
                            <b-list-group-item to="/information/data-and-validation">Data and validation</b-list-group-item>
                            <b-list-group-item to="/information/cga-characteristics">Characteristics</b-list-group-item>
                            <b-list-group-item to="/information/citation-information">Citation information</b-list-group-item>
                            <b-list-group-item to="/information/batch-instructions">Instructions for batch edits</b-list-group-item>
                            <b-list-group-item to="/information/themes">Themes</b-list-group-item>
                            <b-list-group-item to="/information/download">Download</b-list-group-item>
                        </b-list-group>
                    </b-collapse>
                </b-card>
            </b-col>
            <b-col cols="12" lg="9">
                <router-view />
            </b-col>
        </b-row>
    </div>
</template>

<style>
#information-nav .list-group-item.router-link-exact-active {
    background-color: #ebeced;
}
</style>
