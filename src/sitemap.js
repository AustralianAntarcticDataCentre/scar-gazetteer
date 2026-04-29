import routes from "./routes"
import { join } from 'node:path'
import Sitemap from 'vite-plugin-sitemap'

async function extractPaths(prefix, routes) {
    async function extract(route) {
        let paths = []
        if (route.path && includeInSitemap(route)) paths.push(join(prefix, route.path))
        if (route.meta?.sitemap?.slugs) paths.push(...await generatePathsFromSlugs(prefix, route))
        if (route.children) paths.push(...await extractPaths(join(prefix, route.path), route.children))
        return paths
    } 

    return (await Promise.all(routes.reduce((p, c) => {
        p.push(extract(c))
        return p
    }, []))).flat(Infinity)
}

function includeInSitemap(route) {
    if (route.redirect) return false
    if (route.meta?.sitemap?.ignoreRoute === true) return false
    if (/\*|\:/.test(route.path)) return false
    return true
}

async function generatePathsFromSlugs(prefix, route) {
    const resources = await route.meta.sitemap.slugs()

    const paths = resources.map((resource) => {
        let path = join(prefix, route.path)

        Object.keys(resource).forEach((property) => {
            path = path.replace(`:${property}`, resource[property])
        })

        return path
    })

    return paths
}

const paths = await extractPaths('', routes)

export default function() {
    return Sitemap({
        hostname: 'https://apps.aad.gov.au/scar-cga',
        dynamicRoutes: paths
    })
}