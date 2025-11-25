<template>
    <div class="d-flex flex-column vh-100">
        <header>
            <h1 class="sr-only">SCAR Composite Gazetteer of Antarctica</h1>
            <div class="pre-nav">
                <b-container class="px-sm-3">
                    This website is an initiative of the <a href="https://scar.org" target="_blank">Scientific Committee on Antarctic Research</a>
                </b-container>
            </div>
            <b-navbar class="main-nav" toggleable="lg">
                <b-container class="px-sm-3">
                    <b-navbar-brand to="/" class="d-flex align-items-center">
                        <img alt="SCAR Logo" src="./assets/scar_logo.svg" class="mr-2" style="width: 2.5em;"/>    
                        Antarctic Place Names
                    </b-navbar-brand>

                    <b-navbar-toggle target="nav-collapse"></b-navbar-toggle>

                    <b-collapse id="nav-collapse" is-nav>
                        <b-navbar-nav class="ml-auto">
                            <b-nav-item to="/search"
                                ><BIconSearch class="mr-1" />Search</b-nav-item
                            >
                            <b-nav-item to="/information"
                                ><BIconInfoCircle class="mr-1" />Information</b-nav-item
                            >
                            <b-nav-item
                                v-if="$store.state.user.isAdmin"
                                to="/place-names/create"
                                ><BIconPlusCircle class="mr-1" />Add place name</b-nav-item
                            >

                            <b-nav-item
                                v-if="!isLoggedIn"
                                @click="$bvModal.show('login-modal')"
                                ><BIconPerson class="mr-1" />Login</b-nav-item
                            >
                            <b-nav-item-dropdown v-else right>
                                <template #button-content>
                                    <BIconPerson class="mr-1" /><em>{{ username }}</em>
                                </template>
                                <b-dropdown-item @click="logout"
                                    >Logout</b-dropdown-item
                                >
                            </b-nav-item-dropdown>
                        </b-navbar-nav>
                    </b-collapse>
                </b-container>
            </b-navbar>

            <LoginModal />
        </header>

        <b-container tag="main" class="flex-grow-1 py-3 py-lg-4">
            <router-view />
        </b-container>

        <footer class="bg-light mt-8">
            <b-container class="py-4" style="font-size: .8rem;">
                <div class="d-flex mb-3" style="max-width: 220px; gap: 1rem">
                    <img src="./assets/scar_logo_sm.png" alt="SCAR logo" class="w-50" />
                </div>
                <p>
                    The SCAR CGA is edited by representatives from <a href="https://www.pnra.aq/" target="_blank">National Antarctic Research Program</a>.
                </p>
                <p class="mb-0">
                    Hosting is provided by the 
                        <a href="https://data.aad.gov.au" target="_blank"
                            >Australian Antarctic Data Centre</a
                        >.
                </p>
            </b-container>
        </footer>
    </div>
</template>

<script>
import { mapActions, mapState } from "vuex";
import LoginModal from "@/components/LoginModal.vue";
import { BIconInfoCircle, BIconPerson, BIconPlusCircle, BIconSearch } from "bootstrap-vue";

export default {
    name: "App",
    components: {
        LoginModal, BIconInfoCircle, BIconPerson, BIconPlusCircle, BIconSearch,
    },
    metaInfo: function () {
        return {
            title: "SCAR Composite Gazetteer of Antarctica",
            meta: [
                {
                    name: "description",
                    content: "SCAR Composite Gazetteer of Antarctica",
                },
                {
                    property: "og:title",
                    content: "SCAR Composite Gazetteer of Antarctica",
                },
                {
                    property: "og:site_name",
                    content: "SCAR Composite Gazetteer of Antarctica",
                },
                { property: "og:type", content: "website" },
                { name: "robots", content: "index,follow" },
            ],
        };
    },
    methods: {
        ...mapActions("user", ["logout"]),
    },
    computed: {
        ...mapState("user", ["isLoggedIn", "username"]),
    },
};
</script>
