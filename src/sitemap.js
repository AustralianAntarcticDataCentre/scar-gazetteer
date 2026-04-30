import routes from "./routes"
import { join } from 'node:path'
import Sitemap from 'vite-plugin-sitemap'

async function extractPaths(prefix, routes) {
    return (await Promise.all(routes.reduce((promises, route) => {
        promises.push(processRoute(prefix, route))
        return promises
    }, []))).flat(Infinity)
}

async function processRoute(prefix, route) {
    let paths = []

    // Add any static paths directly to the list
    if (route.path && !routeExplicitlyIgnored(route) && !routeIsRedirect(route) && !routeIsDynamic(route)) {
        paths.push(join(prefix, route.path))
    }

    // Generate dynamic paths if provided for
    if (routeIsDynamic(route) && route.meta?.sitemap?.slugs) {
        paths.push(...await generatePathsFromSlugs(prefix, route))
    }

    // Continue processing any child routes
    if (route.children) {
        paths.push(...await extractPaths(join(prefix, route.path), route.children))
    }

    return paths
}

function routeExplicitlyIgnored(route) {
    return !!route.meta?.sitemap?.ignoreRoute === true
}

function routeIsRedirect(route) {
    return !!route.redirect
}

function routeIsDynamic(route) {
    return /\*|\:/.test(route.path)
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

export default function(basePath) {
    return Sitemap({
        hostname: 'https://apps.aad.gov.au',
        basePath: basePath.replace(/\/+$/, ''), // Strip trailing slashes
        dynamicRoutes: paths,
    })
}