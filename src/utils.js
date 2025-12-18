import { byNumeric as isoCountryByNumeric } from 'iso-country-codes'

export function getNameForNumericIsoCountryCode(code) {
    code = String(code).padStart(3, '0')
    if (Object.prototype.hasOwnProperty.call(isoCountryByNumeric, code)) {
        return isoCountryByNumeric[code].altName || isoCountryByNumeric[code].name
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