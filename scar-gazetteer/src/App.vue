<template>
    <div class="d-flex flex-column vh-100">
        <b-navbar toggleable="lg" type="dark" variant="info">
            <b-container class="px-sm-3">
                <b-navbar-brand to="/">SCAR CGA</b-navbar-brand>

                <b-navbar-toggle target="nav-collapse"></b-navbar-toggle>

                <b-collapse id="nav-collapse" is-nav>
                    <!-- Right aligned nav items -->
                    <b-navbar-nav class="ml-auto">
                        <b-nav-item to="/search"
                            ><BIconSearch /> Search</b-nav-item
                        >
                        <b-nav-item to="/information"
                            ><BIconInfoCircle /> Information</b-nav-item
                        >
                        <b-nav-item
                            v-if="$store.state.user.isAdmin"
                            to="/new-name"
                            ><BIconPlusCircle /> Add place name</b-nav-item
                        >

                        <b-nav-item
                            v-if="!isLoggedIn"
                            @click="$bvModal.show('login-modal')"
                            ><BIconPerson /> Login</b-nav-item
                        >
                        <b-nav-item-dropdown v-else right>
                            <template #button-content>
                                <BIconPerson /> <em>{{ username }}</em>
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

        <b-container tag="main" class="flex-grow-1 py-3 py-lg-4">
            <router-view />
        </b-container>

        <footer class="bg-light mt-8">
            <b-container class="py-4">
                <p>
                    The SCAR CGA is edited by Italian representatives from Comitato per i nomi geografici antartici.
                </p>
                <p class="mb-0">
                    The SCAR CGA is hosted by the
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
import { setDefaultToken } from "vue-postgrest";
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
    mounted: function () {
        setDefaultToken(this.$store.getters["user/getToken"]);
    },
};
</script>

<style>
/* @import '~@/assets/scar_gaz.css';
@import '~@/assets/main.css'; */

.max-w-sm {
    max-width: var(--breakpoint-sm);
}

.max-w-md {
    max-width: var(--breakpoint-md);
}

.max-w-lg {
    max-width: var(--breakpoint-lg);
}

/* Remove default Bootstrap margin below pagination elements */
.pagination {
    margin-bottom: 0;
}

/* Add required indicator to input labels */
label:has(+ div [required])::before {
  content: '*';
  color: red;
}
</style>
