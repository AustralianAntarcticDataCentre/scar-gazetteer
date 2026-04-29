const Main = () => import("@/pages/Main.vue")
const Search = () => import("@/pages/Search.vue")
const SearchResults = () => import("@/pages/SearchResults.vue")
const PlaceName = () => import("@/pages/PlaceName.vue")
const Information = () => import("@/pages/Information.vue")
const InformationDownload = () => import("@/pages/InformationDownload.vue")
const InformationGeneral = () => import("@/pages/InformationGeneral.vue")
const InformationTerminology = () => import("@/pages/InformationTerminology.vue")
const InformationBatchInstructions = () => import("@/pages/InformationBatchInstructions.vue")
const InformationHistory = () => import("@/pages/InformationHistory.vue")
const InformationThemes = () => import("@/pages/InformationThemes.vue")
const InformationCGACharacteristics = () => import("@/pages/InformationCharacteristics.vue")
const InformationData = () => import("@/pages/InformationData.vue")
const InformationCitation = () => import("@/pages/InformationCitation.vue")
const InformationGlossary = () => import("@/pages/InformationGlossary.vue")
const InformationNamingAuthorities = () => import("@/pages/InformationNamingAuthorities.vue")
const InformationStatistics = () => import("@/pages/InformationStatistics.vue")
const NewPlaceName = () => import("@/pages/NewPlaceName.vue")
const EditPlaceName = () => import("@/pages/EditPlaceName.vue")
const NotFound = () => import("@/pages/NotFound.vue")

const routes = [
    {
        path: '/',
        name: 'Home',
        component: Main,
    },
    {
        path: '/information',
        component: Information,
        children: [
            {
                path: '',
                component: InformationGeneral
            },
            {
                path: 'terminology',
                component: InformationTerminology
            },
            {
                path: 'batch-instructions',
                component: InformationBatchInstructions
            },
            {
                path: 'history',
                component: InformationHistory
            },
            {
                path: 'themes',
                component: InformationThemes
            },
            {
                path: 'characteristics',
                component: InformationCGACharacteristics
            },
            {
                path: 'data-and-validation',
                component: InformationData
            },
            {
                path: 'citation-information',
                component: InformationCitation
            },
            {
                path: 'glossary',
                component: InformationGlossary
            },
            {
                path: 'naming-authorities',
                component: InformationNamingAuthorities
            },
            {
                path: 'statistics',
                component: InformationStatistics
            },
            {
                path: 'download',
                component: InformationDownload
            },
        ]
    },
    {
        path: '/search',
        component: Search,
    },
    {
        path: '/search/results',
        component: SearchResults,
        meta: {
            sitemap: { ignoreRoute: true }
        }
    },
    {
        path: '/place-names/create',
        component: NewPlaceName,
        meta: {
            requiresAdmin: true,
            sitemap: { ignoreRoute: true }
        }
    },
    {
        path: '/place-names/:id',
        component: PlaceName,
        meta: {
            sitemap: {
                slugs: getPlaceIds
            }
        }
    },
    {
        path: '/place-names/:id/edit',
        component: EditPlaceName,
        meta: {
            requiresAdmin: true,
            sitemap: { ignoreRoute: true }
        }
    },
    // Handle legacy internal links
    {
        path: '/display_name.cfm',
        redirect: to => {
            if (!to.query.gaz_id) return { path: '/search' }
            return { path: `/place-names/${to.query.gaz_id}` }
        }
    },
    {
        path: '*',
        component: NotFound,
    }
]

async function getPlaceIds() {
    const response = await fetch('https://apps.aad.gov.au/scar-cga/api/place_names?select=id:name_id')
    const data = await response.json()
    return data
}

export default routes
