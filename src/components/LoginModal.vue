<template>
    <b-modal
        id="login-modal"
        title="Login"
        hide-header-close
        @ok="handleLogin"
        @hidden="resetForm"
    >
        <b-form @submit.prevent="handleLogin">
            <p>Login using an <a href="https://data.aad.gov.au" target="_blank">AADC</a> account.</p>

            <b-form-group label="Username" label-for="username">
                <b-form-input
                    id="username"
                    v-model="form.username"
                    required
                    autofocus
                    autocomplete="username"
                />
            </b-form-group>

            <b-form-group label="Password" label-for="password">
                <b-form-input
                    id="password"
                    v-model="form.password"
                    type="password"
                    required
                    autocomplete="password"
                />
                <template #description>
                    <a href="https://data.aad.gov.au/user/forgotpassword" target="_blank">Forgot password?</a>
                </template>
            </b-form-group>

            <input type="submit" hidden />

            <b-alert
                v-if="
                    loginError &&
                    form.submitted &&
                    loginError.response.status === 401
                "
                variant="danger"
                show
            >
                Invalid username or password.
            </b-alert>
            <b-alert
                v-if="
                    loginError &&
                    form.submitted &&
                    loginError.response.status === 429
                "
                variant="warning"
                show
            >
                Error: Too many requests.
            </b-alert>
            <b-alert
                v-if="
                    loginError &&
                    form.submitted &&
                    loginError.response.status !== 401 &&
                    loginError.response.status !== 429
                "
                variant="warning"
                show
            >
                Error: Could not log in.
            </b-alert>
        </b-form>
    </b-modal>
</template>

<script>
import { mapActions, mapState } from "vuex";

export default {
    data: function () {
        return {
            form: {
                username: "",
                password: "",
                submitted: false,
            },
        };
    },
    methods: {
        ...mapActions("user", ["authenticate", "logout"]),
        handleLogin: function (bvModalEvt) {
            if (bvModalEvt) {
                bvModalEvt.preventDefault();
            }
            this.form.submitted = true;
            this.authenticate({
                username: this.form.username,
                password: this.form.password,
            }).then(() => {
                if (!this.loginError) {
                    this.$bvModal.hide("login-modal");
                }
            });
        },
        resetForm: function () {
            this.form.username = "";
            this.form.password = "";
            this.form.submitted = false;
        },
    },
    computed: {
        ...mapState("user", ["isLoggedIn", "loginError", "username"]),
    },
};
</script>
