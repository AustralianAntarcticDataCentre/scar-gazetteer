import axios from 'axios'
import Cookie from 'js-cookie'
import decode from 'jwt-decode'

const AAD_JWT_TOKEN = 'aad_token'

const ADMIN_ROLES = [
    'AADC',
    'AADC_DEV',
    'GAZ_EDIT'
]

function getToken() {
    return Cookie.get(AAD_JWT_TOKEN)
}

function isTokenExpired(token) {
    const tokenDecoded = decode(token)
    if (!tokenDecoded.exp) {
        return null
    }

    const date = new Date(0)
    date.setUTCSeconds(tokenDecoded.exp)

    return date < new Date()
}

export default {
    namespaced: true,
    state: {
        isLoggedIn: false,
        username: '',
        email_address: '',
        isAdmin: false,
        aadToken: '',
        loginError: null
    },
    getters: {
        getToken: (state) => {
            return state.aadToken
        }
    },
    mutations: {
        login: (state, userInfo) => {
            state.isLoggedIn = true
            state.username = userInfo.username
            state.aadToken = userInfo.aadToken
            state.isAdmin = userInfo.isAdmin
        },
        logout: state => {
            state.isLoggedIn = false
            state.username = ''
            state.isAdmin = false
            state.aadToken = ''
        },
        setError: (state, error) => {
            state.loginError = error
        }
    },
    actions: {
        async authenticate({ dispatch, commit }, loginInfo) {
            try {
                commit('setError', null)
                let response = await axios.post(`/user/api/authenticate`, loginInfo)

                Cookie.set(AAD_JWT_TOKEN, response.data.token, {
                    expires: new Date(response.data.expires),
                    secure: location.protocol === 'https:'
                })

                dispatch('checkLoggedIn')
            } catch (error) {
                console.log(`Login Error: ${error}`)
                commit('setError', error)
            }
        },
        checkLoggedIn({ commit }) {
            const aadToken = getToken(AAD_JWT_TOKEN)
            let isAdmin = false;

            if (aadToken) {
                if (isTokenExpired(aadToken)) {
                    commit('logout')
                    Cookie.remove(AAD_JWT_TOKEN)
                    return
                }

                const tokenDecoded = decode(aadToken)

                if (ADMIN_ROLES.some(role => tokenDecoded.roles.includes(role))) {
                    isAdmin = true
                }

                commit('login', {
                    username: tokenDecoded.user.username,
                    aadToken: aadToken,
                    isAdmin: isAdmin
                })

            } else {
                commit('logout')
            }
        },
        logout({ dispatch, commit }) {
            Cookie.remove(AAD_JWT_TOKEN)
            commit('setError', false)
            dispatch('checkLoggedIn')
            window.location = '/'
        }
    }
}
