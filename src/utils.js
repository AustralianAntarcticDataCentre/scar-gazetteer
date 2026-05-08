import isoCountries from './countries.json'

export function getNameForNumericIsoCountryCode(code) {
    code = String(code).padStart(3, '0')
    const country = isoCountries.find((c => c['country-code'] === code))
    
    if (country) {
        return country.name
    }

    console.error(`Unknown ISO country code: '${code}'`)
    return ''
}

/**
 * Joins multiple path components and removes duplicate forward slashes, except for where they follow a colon.
 * @param  {...string} paths 
 * @returns {string}
 */
export function join(...paths) {
    return paths.join('/').replaceAll(/(?<!:)\/{2,}/g, '/')
}